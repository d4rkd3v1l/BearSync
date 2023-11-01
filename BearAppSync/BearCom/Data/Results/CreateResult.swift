//
//  CreateResult.swift
//  BearAppSync
//
//  Created by d4Rk on 29.10.23.
//

import Foundation

struct CreateResult: ResultType  {
    let identifier: NoteId
    let title: String
    
    init?(queryItems: [URLQueryItem]) {
        guard let identifierString = queryItems["identifier"],
              let identifier = UUID(uuidString: identifierString),
              let title = queryItems["title"] else { return nil }
        
        self.identifier = identifier
        self.title = title
    }
}
