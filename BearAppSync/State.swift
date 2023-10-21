//
//  State.swift
//  BearAppSync
//
//  Created by d4Rk on 21.10.23.
//

import Foundation

typealias InstanceId = UUID
typealias NoteId = String
typealias FileId = UUID

struct State: Codable {
    struct Note: Codable {
        let fileId: FileId
        let references: [InstanceId: NoteId]
    }
    
    var notes: [Note] = []
    
    func noteId(for fileId: FileId, in instanceId: InstanceId) -> NoteId? {
        notes.first(where: { note in
            note.fileId == fileId
        })?.references[instanceId]
    }
    
    func fileId(for noteId: NoteId, in instanceId: InstanceId) -> FileId? {
        notes.first(where: { note in
            note.references[instanceId] == noteId
        })?.fileId
    }
    
    mutating func addNote(with noteId: NoteId, for instanceId: InstanceId) -> FileId {
        let note = Note(fileId: FileId(), references: [instanceId: noteId])
        notes.append(note)
        return note.fileId
    }
    
    mutating func addReference() {}
    mutating func removeReference() {}
    
    static func readState(from url: URL) throws -> Self {
        let data = try Data(contentsOf: url)
        let state = try JSONDecoder().decode(State.self, from: data)
        return state
    }
    
    func writeState(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let state = try encoder.encode(self)
        try state.write(to: url)
    }
}
