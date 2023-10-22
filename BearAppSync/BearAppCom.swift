//
//  BearAppCom.swift
//  BearAppSync
//
//  Created by d4Rk on 22.10.23.
//

import SwiftUI

struct SearchNote: Decodable {
    let title: String
    let identifier: String
    let creationDate: String
    let modificationDate: String
    let tags: String
    let pin: String
}

class BearAppCom {
    static let shared = BearAppCom()
    
    // TODO: Use AsyncSequence here like notifications, and handle url parsing here instead of BearAppSyncApp.swift
    // https://www.avanderlee.com/concurrency/asyncsequence/
    func handleURL(_ url: URL) {
        
    }
    
    func search(tag: String) async -> [NoteId] {
        let url = URL(string: "bear://x-callback-url/search?token=\(bearAPIToken)&tag=\(tag)&show_window=false&x-success=bearappsync://x-callback-url/search?status%3dsuccess%26tag%3d\(tag)")!
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
    
    // TODO: Ignore trashed notes!
    func openNote(_ noteId: NoteId) async -> Note {
        
    }
    
    func create(with text: String, for fileId: FileId) async throws -> NoteId {
        let url = URL(string: "bear://x-callback-url/create?text=\(text)&open_note=false&x-success=bearappsync://x-callback-url/create?status%3dsuccess%26fileId%3d\(fileId)&x-error=bearappsync://x-callback-url/create?status%3derror%26fileId%3d\(fileId)")!
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
}
