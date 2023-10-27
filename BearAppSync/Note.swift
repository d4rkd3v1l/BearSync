//
//  Note.swift
//  BearAppSync
//
//  Created by d4Rk on 04.10.23.
//

import Foundation
import RegexBuilder

struct Note {
    let id: String
    let text: String
    
    var tags: [String] {
        let regex = Regex {
            "#"
            OneOrMore {
                CharacterClass(
                    .anyOf("#(){}"),
                    .whitespace
                )
                .inverted
            }
        }
        
        let matches = text.matches(of: regex)
        var result = matches.map { match in
            String(text[match.range.lowerBound..<match.range.upperBound].dropFirst())
        }
        
        // Nested tags
        result.enumerated().forEach {
            let nested = $0.element.split(separator: "/")
            for index in 0..<nested.count-1 {
                result.append(nested[0...index].joined(separator: "/"))
            }
            
        }
        
        return result
    }
}

extension Note {    
    func write(to baseURL: URL) throws {
        let filename = baseURL.appending(component: id)
        try text.write(to: filename, atomically: true, encoding: .utf8)
    }
}

import CryptoKit
extension String {
    var sha256: String? {
        guard let data = self.data(using: .utf8) else { return nil }
        
        let digest = SHA256.hash(data: data)
        let hashString = digest
            .compactMap { String(format: "%02x", $0) }
            .joined()
        
        return hashString
    }
}
