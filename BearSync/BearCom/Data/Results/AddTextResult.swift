//
//  AddTextResult.swift
//  BearSync
//
//  Created by d4Rk on 29.10.23.
//

import Foundation

struct AddTextResult: ResultType  {
    let note: String
    let title: String
    
    init?(queryItems: [URLQueryItem]) {
        guard let note = queryItems["note"],
              let title = queryItems["title"] else { return nil }
        
        self.note = note
        self.title = title
    }
}
