//
//  ContentView.swift
//  BearAppSync
//
//  Created by d4Rk on 04.10.23.
//

import SwiftUI
import SQLite3

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Sync") {
                Task {
                    await exportNotes()
                }
            }
            Button("Search") {
                Task {
                    let result = await BearAppCom.shared.search(tag: "test")
                    print(result)
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
func exportNotes() async {
    let bearDBFilePath = ("~/Library/Group Containers/9K33E3U3T4.net.shinyfrog.bear/Application Data/database.sqlite" as NSString).expandingTildeInPath
    
    do {
        let openPanelHelper = OpenPanelHelper()
        let url = try await openPanelHelper.openFile(at: NSURL.fileURL(withPath: bearDBFilePath, isDirectory: false), bookmark: "bearDBFilePathBookmark")
        try await exportNotesFromDB(at: url.path(percentEncoded: false))
    } catch {
        print("ERROR: \(error)")
    }
}

private let tags = ["test", "test2"]

@MainActor
private func exportNotesFromDB(at path: String) async throws {
    var db: OpaquePointer?
    defer { sqlite3_close(db) }
    
    guard sqlite3_open(path, &db) == SQLITE_OK else {
        print("Error opening database.")
        return
    }
    
    print("Database opened.")

    var query: OpaquePointer?
    defer { sqlite3_finalize(query) }
    let queryString = "SELECT ZUNIQUEIDENTIFIER, ZTITLE, ZTEXT FROM ZSFNOTE WHERE ZTRASHED = '0'"
    
    if sqlite3_prepare_v2(db, queryString, -1, &query, nil) == SQLITE_OK {
        let openPanelHelper = OpenPanelHelper()
        let gitRepoURL = try await openPanelHelper.openDirectory(at: nil, bookmark: "gitRepoPathBookmark")
        let stateURL = gitRepoURL.appending(path: "state.json")
        var state = (try? State.readState(from: stateURL)) ?? State()
        let instanceId = InstanceId(uuidString: UserDefaults.standard.string(forKey: "instanceId") ?? InstanceId().uuidString) ?? InstanceId()
        UserDefaults.standard.set(instanceId.uuidString, forKey: "instanceId")
        
        while sqlite3_step(query) == SQLITE_ROW {
            let rawUuid = sqlite3_column_text(query, 0)
            let rawTitle = sqlite3_column_text(query, 1)
            let rawText = sqlite3_column_text(query, 2)
            
            // Note: Encrypted (password protected) notes don't have `ZTEXT` property set, and anyway we don't want to export empty notes -> skip them.
            guard let rawUuid, let rawTitle, let rawText else {
                continue
            }
            
            let note = Note(rawUuid: rawUuid, rawTitle: rawTitle, rawText: rawText)
            guard note.tags.contains(where: { tags.contains($0) }) else {
                continue
            }
            
            // TODO: Write .md files!
            print(note.title)
            
            let fileId = state.fileId(for: note.uuid, in: instanceId) ?? state.addNote(with: note.uuid, for: instanceId)
            
            let filename = gitRepoURL.appending(component: fileId.uuidString)
            try note.text.write(to: filename, atomically: true, encoding: .utf8)
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
                    let updateURL = URL(string: "bear://x-callback-url/add-text?id=\(noteId)&text=\(text)&mode=replace_all&open_note=false")!
                    NSWorkspace.shared.open(updateURL)
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

