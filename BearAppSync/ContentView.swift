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
            Button("Test") {
                Task {
                    await test()
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
func test() async {
    let bearDBFilePath = ("~/Library/Group Containers/9K33E3U3T4.net.shinyfrog.bear/Application Data/database.sqlite" as NSString).expandingTildeInPath
    
    let openPanelHelper = OpenPanelHelper()
    let url = try! await openPanelHelper.openFile(at: NSURL.fileURL(withPath: bearDBFilePath, isDirectory: false), bookmark: "bearDBFilePathBookmark")
    await exportNotesFromDB(at: url.path(percentEncoded: false))
}

private let tags = ["test", "test2"]

@MainActor
private func exportNotesFromDB(at path: String) async {
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
            let url = try! await openPanelHelper.openDirectory(at: nil, bookmark: "gitRepoPathBookmark")
            try! note.write(to: url)
        }
    }
}
