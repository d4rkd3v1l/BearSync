//
//  ContentView.swift
//  BearAppSync
//
//  Created by d4Rk on 04.10.23.
//

import SwiftUI

private let tags = ["test", "test2"]

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Sync") {
                Task {
                    try await synchronize()
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

@MainActor
func synchronize() async throws {
    let openPanelHelper = OpenPanelHelper()
    let gitRepoURL = try await openPanelHelper.openDirectory(at: nil, bookmark: "gitRepoPathBookmark")
    let stateURL = gitRepoURL.appending(path: "state.json")
    var state = (try? State.readState(from: stateURL)) ?? State()
    let instanceId = InstanceId(uuidString: UserDefaults.standard.string(forKey: "instanceId") ?? InstanceId().uuidString) ?? InstanceId()
    UserDefaults.standard.set(instanceId.uuidString, forKey: "instanceId")
    
    for tag in tags {
        let searchResult = await BearAppCom.shared.search(tag: tag)
        
        for noteId in searchResult?.notes.map({ $0.identifier }) ?? [] {
            guard let openNoteResult = await BearAppCom.shared.openNote(noteId) else { continue }
            let fileId = state.fileId(for: openNoteResult.identifier, in: instanceId) ?? state.addNote(with: openNoteResult.identifier, for: instanceId)
            
            let filename = gitRepoURL.appending(component: fileId.uuidString)
            try openNoteResult.note.write(to: filename, atomically: true, encoding: .utf8)
        }
    }
    
    try state.writeState(to: stateURL)
    
    SystemCom.bash(currentDirectory: gitRepoURL, "git config user.email \"BearAppSync@d4Rk.com\" && git config user.name \"BearAppSync\"")
    SystemCom.bash(currentDirectory: gitRepoURL, "git config pull.rebase false")
    SystemCom.bash(currentDirectory: gitRepoURL, "git remote set-url origin https://\(gitHubToken)@github.com/d4rkd3v1l/bear-sync.git")
    SystemCom.bash(currentDirectory: gitRepoURL, "git add . && git commit -m \"test\"")
    SystemCom.bash(currentDirectory: gitRepoURL, "git pull")

    state = (try? State.readState(from: stateURL)) ?? State()
    
    let files = try FileManager.default.contentsOfDirectory(at: gitRepoURL, includingPropertiesForKeys: nil)
    for file in files {
        if let fileId = FileId(uuidString: file.lastPathComponent) {
            let text = try String(contentsOf: gitRepoURL.appending(component: fileId.uuidString))
            let textPercentEncoded = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        
            if let noteId = state.noteId(for: fileId, in: instanceId) {
                let openNoteResult = await BearAppCom.shared.openNote(noteId)
                // Update
                if openNoteResult?.note.sha256 != text.sha256 {
                    print("Update \(fileId)")
                    _ = try await BearAppCom.shared.addText(textPercentEncoded, to: noteId)
                } else {
                    print("Skip \(fileId)")
                }
            } else { // Create
                print("Create \(fileId)")
                guard let noteId = try await BearAppCom.shared.create(with: textPercentEncoded, for: fileId)?.identifier,
                      state.addReference(to: fileId, noteId: noteId, instanceId: instanceId) else {
                    fatalError("Could not add reference to note!")
                }
            }
        }
    }

    try state.writeState(to: stateURL)
    SystemCom.bash(currentDirectory: gitRepoURL, "git add . && git commit -m \"test2\"")
    SystemCom.bash(currentDirectory: gitRepoURL, "git push")
}
