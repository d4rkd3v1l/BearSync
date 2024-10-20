//
//  OpenNoteResult.swift
//  BearSync
//
//  Created by d4Rk on 29.10.23.
//

import Foundation
import RegexBuilder

struct OpenNoteResult: ResultType  {
    let note: String // ZTEXT
    let identifier: NoteId // ZUNIQUEIDENTIFIER
    let title: String // ZTITLE
    let tags: String
    let isTrashed: String // ZTRASHED
    let modificationDate: String // ZMODIFICATIONDATE
    let creationDate: String // ZCREATIONDATE
}

extension OpenNoteResult {
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

    /// FileId format: `[BearSync FileId]: <> (UUIDv4)`
    var fileId: FileId? {
        let pattern = Regex {
            "[BearSync FileId]: <> ("
            Capture {
              Regex {
                Repeat(count: 8) {
                  CharacterClass(
                    ("0"..."9"),
                    ("A"..."F")
                  )
                }
                "-"
                Repeat(count: 4) {
                  CharacterClass(
                    ("0"..."9"),
                    ("A"..."F")
                  )
                }
                "-"
                One(.anyOf("4"))
                Repeat(count: 3) {
                  CharacterClass(
                    ("0"..."9"),
                    ("A"..."F")
                  )
                }
                "-"
                One(.anyOf("89AB"))
                Repeat(count: 3) {
                  CharacterClass(
                    ("0"..."9"),
                    ("A"..."F")
                  )
                }
                "-"
                Repeat(count: 12) {
                  CharacterClass(
                    ("0"..."9"),
                    ("A"..."F")
                  )
                }
              }
            }
            ")"
          }
          .anchorsMatchLineEndings()

        if let match = note.firstMatch(of: pattern) {
            let (_, fileId) = match.output
            return UUID(uuidString: String(fileId))
        }

        return nil
    }
}
