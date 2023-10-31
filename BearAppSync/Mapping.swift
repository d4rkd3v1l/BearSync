//
//  State.swift
//  BearAppSync
//
//  Created by d4Rk on 21.10.23.
//

import Foundation

typealias InstanceId = UUID
typealias NoteId = UUID
typealias FileId = UUID

struct Mapping: Codable, Equatable {
    struct Note: Codable, Equatable {
        let fileId: FileId
        var references: [InstanceId: NoteId]
//        var isDeleted: Bool = false
    }
    
    private (set) var notes: [Note] = []
    
    // MARK: - Lifecycle
    
    init(notes: [Note] = []) {
        self.notes = notes
    }
    
    // MARK: - Modifications
    
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
    
    // New note created locally
    mutating func addNote(with noteId: NoteId, for instanceId: InstanceId) -> FileId {
        let note = Note(fileId: FileId(), references: [instanceId: noteId])
        notes.append(note)
        return note.fileId
    }
    
    mutating func removeNote(_ note: Note) {
        notes.removeAll(where: { $0 == note })
    }
    
//    // Note removed locally
//    mutating func removeNote(with fileId: FileId, for instanceId: InstanceId) {
//        for var note in notes {
//            if note.fileId == fileId {
//                note.references[instanceId] = nil
//                
//                if note.references.isEmpty {
//                    notes.removeAll(where: { $0 == note })
//                } else {
//                    note.isDeleted = true
//                }
//            }
//        }
//    }
    
    // New note from remote
    @discardableResult
    mutating func addReference(to fileId: FileId, noteId: NoteId, instanceId: InstanceId) -> Bool {
        for (index, note) in notes.enumerated() {
            if note.fileId == fileId {
                var note = note
                note.references[instanceId] = noteId
                notes[index] = note
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Persistence
    
    static func load(from url: URL) throws -> Self {
        let data = try Data(contentsOf: url)
        let state = try JSONDecoder().decode(Mapping.self, from: data)
        return state
    }
    
    func save(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let state = try encoder.encode(self)
        try state.write(to: url)
    }
}
