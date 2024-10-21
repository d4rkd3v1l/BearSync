//
//  String+Extensions.swift
//  BearSync
//
//  Created by d4Rk on 30.10.23.
//

import CryptoKit
import RegexBuilder

extension String {
    var sha256: String? {
        guard let data = self.data(using: .utf8) else { return nil }
        
        let digest = SHA256.hash(data: data)
        let hashString = digest
            .compactMap { String(format: "%02x", $0) }
            .joined()
        
        return hashString
    }

    var sanitizedMailName: String {
        let notAllowed = Regex {
          OneOrMore {
            CharacterClass(
              .anyOf("._%+-"),
              ("a"..."z"),
              ("A"..."Z"),
              ("0"..."9")
            ).inverted
          }
        }
        .anchorsMatchLineEndings()

        return self.replacing(notAllowed, with: "")
    }
}
