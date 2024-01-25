//
//  SQLiteCom.swift
//  BearSync
//
//  Created by d4Rk on 24.01.24.
//

import Foundation
import SQLite3
import RegexBuilder

enum SQLiteComError: Error {
    case unknown
    case couldNotOpenDatabase
    case couldNotExecuteQuery
    case couldNotBindParameter
    case noteNotFound
    case couldNotParseNote
}

class SQLiteCom {
    func search(tag: String) async throws -> SearchResult {
        let path = try await dbPath()
        let notes = try await notes(at: path, for: tag)

        return SearchResult(notes: notes)
    }

    private func dbPath() async throws -> String {
        let bearDBFilePath = ("~/Library/Group Containers/9K33E3U3T4.net.shinyfrog.bear/Application Data/database.sqlite" as NSString).expandingTildeInPath

        if let url = try? await OpenPanelHelper().getURL(for: Constants.UserDefaultsKey.bearAppSQLiteDBPathBookmark.rawValue) {
            return url.path(percentEncoded: false)
        }

        let url = try await OpenPanelHelper().openFile(at: NSURL.fileURL(withPath: bearDBFilePath), bookmark: Constants.UserDefaultsKey.bearAppSQLiteDBPathBookmark.rawValue)
        return url.path(percentEncoded: false)
    }

    private func notes(at path: String, for tag: String) async throws -> [SearchResult.Note] {
        var db: OpaquePointer?
        defer { sqlite3_close(db) }

        guard sqlite3_open(path, &db) == SQLITE_OK else {
            throw SQLiteComError.couldNotOpenDatabase
        }

        print("Database opened.")

        var query: OpaquePointer?
        defer { sqlite3_finalize(query) }

        let queryString = "SELECT ZTITLE, ZUNIQUEIDENTIFIER, ZCREATIONDATE, ZMODIFICATIONDATE, ZPINNED, ZTEXT FROM ZSFNOTE WHERE ZTRASHED = '0'"

        guard sqlite3_prepare_v2(db, queryString, -1, &query, nil) == SQLITE_OK else {
            throw SQLiteComError.couldNotExecuteQuery
        }

        var notes: [SearchResult.Note] = []

        while sqlite3_step(query) == SQLITE_ROW {
            let rawTitle = sqlite3_column_text(query, 0)
            let rawIdentifier = sqlite3_column_text(query, 1)
            let rawCreationDate = sqlite3_column_text(query, 2)
            let rawModificationDate = sqlite3_column_text(query, 3)
            let rawPinned = sqlite3_column_text(query, 4)
            let rawText = sqlite3_column_text(query, 5)

            // Note: Encrypted (password protected) notes don't have `ZTEXT` property set, and anyway we don't want to export empty notes -> skip them.
            guard let rawTitle,
                  let rawIdentifier,
                  let rawCreationDate,
                  let rawModificationDate,
                  let rawPinned,
                  let rawText else {
                continue
            }

            let text = String(cString: rawText)

            // Filter tags
            guard text.tags.contains(where: { $0 == tag }) else {
                continue
            }


            let note = SearchResult.Note(title: String(cString: rawTitle),
                                         identifier: String(cString: rawIdentifier),
                                         creationDate: String(cString: rawCreationDate),
                                         modificationDate: String(cString: rawModificationDate),
                                         tags: "",
                                         pin: String(cString: rawPinned))

            notes.append(note)
        }

        return notes
    }

    func openNote(_ noteId: NoteId) async throws -> OpenNoteResult {
        let path = try await dbPath()
        return try await note(at: path, for: noteId)
    }

    private func note(at path: String, for noteId: String) async throws -> OpenNoteResult {
        var db: OpaquePointer?
        defer { sqlite3_close(db) }

        guard sqlite3_open(path, &db) == SQLITE_OK else {
            throw SQLiteComError.couldNotOpenDatabase
        }

        print("Database opened.")

        var query: OpaquePointer?
        defer { sqlite3_finalize(query) }
        let queryString = "SELECT ZTEXT, ZUNIQUEIDENTIFIER, ZTITLE, ZTRASHED, ZMODIFICATIONDATE, ZCREATIONDATE FROM ZSFNOTE WHERE ZUNIQUEIDENTIFIER = ?"

        guard sqlite3_prepare_v2(db, queryString, -1, &query, nil) == SQLITE_OK else {
            throw SQLiteComError.couldNotExecuteQuery
        }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        guard sqlite3_bind_text(query, 1, noteId, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
            throw SQLiteComError.couldNotBindParameter
        }

        guard sqlite3_step(query) == SQLITE_ROW else {
            throw SQLiteComError.noteNotFound
        }
        let rawText = sqlite3_column_text(query, 0)
        let rawIdentifier = sqlite3_column_text(query, 1)
        let rawTitle = sqlite3_column_text(query, 2)
        let rawTrashed = sqlite3_column_text(query, 3)
        let rawModificationDate = sqlite3_column_text(query, 4)
        let rawCreationDate = sqlite3_column_text(query, 5)

        // Note: Encrypted (password protected) notes don't have `ZTEXT` property set, and anyway we don't want to export empty notes -> skip them.
        guard let rawText,
              let rawIdentifier,
              let rawTitle,
              let rawTrashed,
              let rawModificationDate,
              let rawCreationDate else {
            throw SQLiteComError.couldNotParseNote
        }

        let text = String(cString: rawText)

        let result = OpenNoteResult(note: text,
                                    identifier: String(cString: rawIdentifier),
                                    title: String(cString: rawTitle),
                                    tags: text.tags.joined(separator: " "),
                                    isTrashed: String(cString: rawTrashed),
                                    modificationDate: String(cString: rawModificationDate),
                                    creationDate: String(cString: rawCreationDate))
        return result
    }
}

private extension String {
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

            let matches = self.matches(of: regex)
            var result = matches.map { match in
                String(self[match.range.lowerBound..<match.range.upperBound].dropFirst())
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
