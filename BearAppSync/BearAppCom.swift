//
//  BearAppCom.swift
//  BearAppSync
//
//  Created by d4Rk on 22.10.23.
//

import SwiftUI
import Combine

enum Status: String {
    case success
    case error
}

enum Action: String {
    case search
    case openNote = "open-note"
    case create
    case addText = "add-text"
}

enum BearAppComResult {
    case search(SearchResult?)
    case openNote(OpenNoteResult?)
    case create(CreateResult?)
    case addText(AddTextResult?)
}

struct SearchResult {
    struct Note: Decodable {
        let title: String
        let identifier: NoteId
        let creationDate: String
        let modificationDate: String
        let tags: String
        let pin: String
    }
    
    let notes: [Note]
    
    init?(queryItems: [URLQueryItem]) {
        guard let notes = queryItems["notes"],
              let data = notes.data(using: .utf8),
              let searchNotes = try? JSONDecoder().decode([SearchResult.Note].self, from: data) else { return nil }
        
        self.notes = searchNotes
    }
}

struct OpenNoteResult {
    let note: String
    let identifier: NoteId
    let title: String
    let tags: String
    let isTrashed: String
    let modificationDate: String
    let creationDate: String
    
    init?(queryItems: [URLQueryItem]) {
        guard let note = queryItems["note"],
              let identifier = queryItems["identifier"],
              let title = queryItems["title"],
              let tags = queryItems["tags"],
              let isTrashed = queryItems["is_trashed"],
              let modificationDate = queryItems["modificationDate"],
              let creationDate = queryItems["creationDate"] else { return nil }
        
        self.note = note
        self.identifier = identifier
        self.title = title
        self.tags = tags
        self.isTrashed = isTrashed
        self.modificationDate = modificationDate
        self.creationDate = creationDate
    }
}

struct CreateResult {
    let identifier: NoteId
    let title: String
    
    init?(queryItems: [URLQueryItem]) {
        guard let identifier = queryItems["identifier"],
              let title = queryItems["title"] else { return nil }
        
        self.identifier = identifier
        self.title = title
    }
}

struct AddTextResult {
    let note: String
    let title: String
    
    init?(queryItems: [URLQueryItem]) {
        guard let note = queryItems["note"],
              let title = queryItems["title"] else { return nil }
        
        self.note = note
        self.title = title
    }
}

class BearAppCom {
    static let shared = BearAppCom()
    
    private let resultsSubject = PassthroughSubject<BearAppComResult, Never>()
    private var results: AsyncStream<BearAppComResult> {
        AsyncStream(bufferingPolicy: .bufferingOldest(0)) { continuation in
            let cancellable = self.resultsSubject.sink { continuation.yield($0) }
            continuation.onTermination = { continuation in
                cancellable.cancel()
            }
        }
    }
    
    func search(tag: String) async -> [NoteId] {
        let url = URL(string: "bear://x-callback-url/search?token=\(bearAPIToken)&tag=\(tag)&show_window=no&x-success=bearappsync://x-callback-url/search?status%3dsuccess%26tag%3d\(tag)&x-error=bearappsync://x-callback-url/search?status%3derror%26tag%3d\(tag)")!
        NSWorkspace.shared.open(url)
        
        let notifications = NotificationCenter.default.notifications(named: Notification.Name(Action.search.rawValue))
        for await notification in notifications {
            if let userInfo = notification.userInfo,
               (userInfo["tag"] as? String) == tag,
               let notes = userInfo["notes"] as? [SearchNote] {
                return notes.map { $0.identifier }
            }
        }
        
        fatalError("Should never get here?!")
    }
    
    func openNote(_ noteId: NoteId) async -> Note {
        let url = URL(string: "bear://x-callback-url/open-note?id=\(noteId)&exclude_trashed=yes&show_window=no&open_note=no&x-success=bearappsync://x-callback-url/open-note?status%3dsuccess%26noteId%3d\(noteId)&x-error=bearappsync://x-callback-url/open-note?status%3derror%26noteId%3d\(noteId)")!
        NSWorkspace.shared.open(url)

        let notifications = NotificationCenter.default.notifications(named: Notification.Name(Action.openNote.rawValue))
        for await notification in notifications {
            if let userInfo = notification.userInfo,
               (userInfo["noteId"] as? String) == noteId,
               let text = userInfo["note"] as? String {
                return Note(id: noteId, text: text)
            }
        }
        
        fatalError("Should never get here?!")
    }
    
    func create(with text: String, for fileId: FileId) async throws -> NoteId {
        let url = URL(string: "bear://x-callback-url/create?text=\(text)&open_note=no&show_window=no&x-success=bearappsync://x-callback-url/create?status%3dsuccess%26fileId%3d\(fileId)&x-error=bearappsync://x-callback-url/create?status%3derror%26fileId%3d\(fileId)")!
        NSWorkspace.shared.open(url)
        
        let notifications = NotificationCenter.default.notifications(named: Notification.Name(Action.create.rawValue))
        for await notification in notifications {
            if let userInfo = notification.userInfo,
               (userInfo["fileId"] as? String) == fileId.uuidString,
               let noteId = userInfo["identifier"] as? String {
                return noteId
            }
        }
        
        fatalError("Should never get here?!")
    }
    
    func addText(_ text: String, to noteId: NoteId) async throws -> Bool {
        let url = URL(string: "bear://x-callback-url/add-text?id=\(noteId)&text=\(text)&mode=replace_all&open_note=no&show_window=no&x-success=bearappsync://x-callback-url/add-text?status%3dsuccess%26noteId%3d\(noteId)")!
        NSWorkspace.shared.open(url)
        
        let notifications = NotificationCenter.default.notifications(named: Notification.Name(Action.addText.rawValue))
        for await notification in notifications {
            if let userInfo = notification.userInfo,
               (userInfo["noteId"] as? String) == noteId {
                return true
            }
        }
        
        fatalError("Should never get here?!")
    }
}
