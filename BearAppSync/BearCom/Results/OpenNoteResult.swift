//
//  OpenNoteResult.swift
//  BearAppSync
//
//  Created by d4Rk on 29.10.23.
//

import Foundation

struct OpenNoteResult: ResultType  {
    let note: String
    let identifier: NoteId
    let title: String
    let tags: String
    let isTrashed: String
    let modificationDate: String
    let creationDate: String
    
    init?(queryItems: [URLQueryItem]) {
        guard let note = queryItems["note"],
              let identifierString = queryItems["identifier"],
              let identifier = UUID(uuidString: identifierString),
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
