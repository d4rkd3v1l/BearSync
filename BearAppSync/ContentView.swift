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
            Button("Export notes") {
                Task {
                    await exportNotes()
                }
            }
            Button("Bla") {
                bash(currentDirectory: URL(string: "file:///Users/1337-h4x0r/")!, "pwd")
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
            
            let openPanelHelper = OpenPanelHelper()
            let url = try await openPanelHelper.openDirectory(at: nil, bookmark: "gitRepoPathBookmark")
            try note.write(to: url)
        }
        
        let openPanelHelper = OpenPanelHelper()
        let url = try await openPanelHelper.openDirectory(at: nil, bookmark: "gitRepoPathBookmark")
        bash(currentDirectory: url, "git config user.email \"BearAppSync@d4Rk.com\" && git config user.name \"BearAppSync\"")
        bash(currentDirectory: url, "git config pull.rebase false")
        bash(currentDirectory: url, "git add . && git commit -m \"test\"")
        bash(currentDirectory: url, "git pull")
        bash(currentDirectory: url, "git push")
        
        let newData = try! String(contentsOf: url.appending(component: "99E0CB12-84E0-4A2B-A3F6-4F0F24C03A47")).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        print(newData)
        let updateURL = URL(string: "bear://x-callback-url/add-text?text=\(newData)&id=99E0CB12-84E0-4A2B-A3F6-4F0F24C03A47&mode=replace_all&open_note=false")!
        print(updateURL)
        NSWorkspace.shared.open(updateURL)
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

