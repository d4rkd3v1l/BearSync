//
//  Note.swift
//  BearAppSync
//
//  Created by d4Rk on 04.10.23.
//

import Foundation
import RegexBuilder

struct Note {
    let uuid: String
    let title: String
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
    init(rawUuid: UnsafePointer<UInt8>, rawTitle: UnsafePointer<UInt8>, rawText: UnsafePointer<UInt8>) {
        uuid = String(cString: rawUuid)
        title = String(cString: rawTitle)
        text = String(cString: rawText)
    }
    
    func write(to baseURL: URL) throws {
        let filename = baseURL.appending(component: uuid)
        try text.write(to: filename, atomically: true, encoding: .utf8)
    }
}
