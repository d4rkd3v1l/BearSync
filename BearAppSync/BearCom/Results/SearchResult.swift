//
//  SearchResult.swift
//  BearAppSync
//
//  Created by d4Rk on 29.10.23.
//

import Foundation

struct SearchResult: ResultType {
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
