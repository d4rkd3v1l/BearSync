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
        let noteIds = await BearAppCom.shared.search(tag: tag)
        
        for noteId in noteIds {
            let note = await BearAppCom.shared.openNote(noteId)
            let fileId = state.fileId(for: note.id, in: instanceId) ?? state.addNote(with: note.id, for: instanceId)
            
            let filename = gitRepoURL.appending(component: fileId.uuidString)
            try note.text.write(to: filename, atomically: true, encoding: .utf8)
        }
    }
    
    try state.writeState(to: stateURL)
    
    bash(currentDirectory: gitRepoURL, "git config user.email \"BearAppSync@d4Rk.com\" && git config user.name \"BearAppSync\"")
    bash(currentDirectory: gitRepoURL, "git config pull.rebase false")
    bash(currentDirectory: gitRepoURL, "git remote set-url origin https://\(gitHubToken)@github.com/d4rkd3v1l/bear-sync.git")
    bash(currentDirectory: gitRepoURL, "git add . && git commit -m \"test\"")
    bash(currentDirectory: gitRepoURL, "git pull")

    state = (try? State.readState(from: stateURL)) ?? State()
    
    let files = try FileManager.default.contentsOfDirectory(at: gitRepoURL, includingPropertiesForKeys: nil)
    for file in files {
        if let fileId = FileId(uuidString: file.lastPathComponent) {
            let text = try String(contentsOf: gitRepoURL.appending(component: fileId.uuidString)).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            // Update
            if let noteId = state.noteId(for: fileId, in: instanceId) {
                _ = try await BearAppCom.shared.addText(text, to: noteId)
            } else { // Create
                let noteId = try await BearAppCom.shared.create(with: text, for: fileId)
                if !state.addReference(to: fileId, noteId: noteId, instanceId: instanceId) {
                    fatalError("Could not add reference to note!")
                }
            }
        }
    }

    try state.writeState(to: stateURL)
    bash(currentDirectory: gitRepoURL, "git add . && git commit -m \"test2\"")
    bash(currentDirectory: gitRepoURL, "git push")
}

@discardableResult
func bash(currentDirectory: URL, _ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c"] + args
    task.currentDirectoryURL = currentDirectory
    
    let standardPipe = Pipe()
    task.standardOutput = standardPipe
    standardPipe.fileHandleForReading.readabilityHandler = { pipe in
        if let line = String(data: pipe.availableData, encoding: .utf8) {
            // Update your view with the new text here
            if line != "" {
                print("STANDARD > \(line)")
            }
        } else {
            print("Error decoding data: \(pipe.availableData)")
        }
    }
    
    let errorPipe = Pipe()
    task.standardError = errorPipe
    errorPipe.fileHandleForReading.readabilityHandler = { pipe in
        if let line = String(data: pipe.availableData, encoding: .utf8) {
            // Update your view with the new text here
            if line != "" {
                print("ERROR > \(line)")
            }
        } else {
            print("Error decoding data: \(pipe.availableData)")
        }
    }

    
    try! task.run()
    task.waitUntilExit()
    return task.terminationStatus
}

