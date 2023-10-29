//
//  ContentView.swift
//  BearAppSync
//
//  Created by d4Rk on 04.10.23.
//

import SwiftUI


private let tags = ["test", "test2"]

@MainActor
func synchronize() async throws {
    print("Starting sync...")
    
    let openPanelHelper = OpenPanelHelper()
    let gitRepoURL = try await openPanelHelper.openDirectory(at: nil, bookmark: "gitRepoPathBookmark")
    let mappingURL = gitRepoURL.appending(path: "mapping.json")
    var mapping = (try? Mapping.load(from: mappingURL)) ?? Mapping()
    let instanceId = InstanceId(uuidString: UserDefaults.standard.string(forKey: "instanceId") ?? InstanceId().uuidString) ?? InstanceId()
    UserDefaults.standard.set(instanceId.uuidString, forKey: "instanceId")
    
    print("Exporting local notes...")
    
    for tag in tags {
        let searchResult = try? await BearCom.shared.search(tag: tag)
        
        for noteId in searchResult?.notes.map({ $0.identifier }) ?? [] {
            guard let openNoteResult = try? await BearCom.shared.openNote(noteId) else { continue }
            let fileId = mapping.fileId(for: openNoteResult.identifier, in: instanceId) ?? mapping.addNote(with: openNoteResult.identifier, for: instanceId)
            
            let filename = gitRepoURL.appending(component: fileId.uuidString)
            try openNoteResult.note.write(to: filename, atomically: true, encoding: .utf8)
        }
    }
    
    try mapping.save(to: mappingURL)
    
    print("Fetching remote notes...")
    
    SystemCom.bash(currentDirectory: gitRepoURL, "git config user.name \"BearAppSync\"")
    SystemCom.bash(currentDirectory: gitRepoURL, "git config user.email \"no@mail.address\"")
    SystemCom.bash(currentDirectory: gitRepoURL, "git config pull.rebase false")
    SystemCom.bash(currentDirectory: gitRepoURL, "git remote set-url origin https://\(gitHubToken)@github.com/d4rkd3v1l/bear-sync.git")
    SystemCom.bash(currentDirectory: gitRepoURL, "git add .")
    SystemCom.bash(currentDirectory: gitRepoURL, "git commit -m \"Sync from \(instanceId.uuidString)\"")
    SystemCom.bash(currentDirectory: gitRepoURL, "git pull")

    mapping = (try? Mapping.load(from: mappingURL)) ?? Mapping()
    
    print("Updating notes...")
    
    let files = try FileManager.default.contentsOfDirectory(at: gitRepoURL, includingPropertiesForKeys: nil)
    for file in files {
        if let fileId = FileId(uuidString: file.lastPathComponent) {
            let text = try String(contentsOf: gitRepoURL.appending(component: fileId.uuidString))
            let textPercentEncoded = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        
            if let noteId = mapping.noteId(for: fileId, in: instanceId) {
                let openNoteResult = try? await BearCom.shared.openNote(noteId)
                // Update
                if openNoteResult?.note.sha256 != text.sha256 {
                    print("Updating note \(fileId)")
                    _ = try await BearCom.shared.addText(textPercentEncoded, to: noteId)
                } else {
                    print("Skipping note \(fileId)")
                }
            } else { // Create
                print("Creating note \(fileId)")
                guard let noteId = try? await BearCom.shared.create(with: textPercentEncoded, for: fileId).identifier,
                      mapping.addReference(to: fileId, noteId: noteId, instanceId: instanceId) else {
                    fatalError("Could not add reference to note!")
                }
            }
        }
    }

    try mapping.save(to: mappingURL)
    
    print("Pushing notes to remote...")
    
    SystemCom.bash(currentDirectory: gitRepoURL, "git add .")
    SystemCom.bash(currentDirectory: gitRepoURL, "git commit -m \"Sync (2) from \(instanceId.uuidString)\"")
    SystemCom.bash(currentDirectory: gitRepoURL, "git push")
    
    print("Done.")
}
