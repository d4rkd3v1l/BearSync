//
//  Action.swift
//  BearSync
//
//  Created by d4Rk on 29.10.23.
//

import Foundation

enum Action: String {
    case search
    case openNote = "open-note"
    case create
    case addText = "add-text"
    case trash
    
    var responseType: ResultType.Type {
        switch self {
        case .search:
            return SearchResult.self

        case .openNote:
            return OpenNoteResult.self
            
        case .create:
            return CreateResult.self
            
        case .addText:
            return AddTextResult.self
            
        case .trash:
            return TrashResult.self
        }
    }
}
