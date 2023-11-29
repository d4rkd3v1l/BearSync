//
//  State.swift
//  BearSync
//
//  Created by d4Rk on 21.10.23.
//

import Foundation

typealias InstanceId = UUID
typealias NoteId = UUID
typealias FileId = UUID

struct Mapping: Codable, Equatable {
    
    // MARK: - Types
    
    struct Note: Codable, Equatable {
        let fileId: FileId
        var references: [InstanceId: NoteId]

        enum CodingKeys: String, CodingKey {
            case fileId
            case references
        }

        init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer = try decoder.container(keyedBy: CodingKeys.self)
            self.fileId = try container.decode(FileId.self, forKey: .fileId)
            let stringReferences = try container.decode([String: String].self, forKey: .references)

            self.references = [:]
            for (stringKey, stringValue) in stringReferences {
                guard let key = UUID(uuidString: stringKey) else {
                    throw DecodingError.dataCorruptedError(forKey: .references,
                                                           in: container,
                                                           debugDescription: "Invalid key '\(stringKey)'")
                }

                guard let value = UUID(uuidString: stringValue) else {
                    throw DecodingError.dataCorruptedError(forKey: .references,
                                                           in: container,
                                                           debugDescription: "Invalid value '\(stringValue)'")
                }

                self.references[key] = value
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(fileId, forKey: .fileId)

            let stringReferences: [String: String] = Dictionary(uniqueKeysWithValues: references.map { ($0.uuidString, $1.uuidString) })
            try container.encode(stringReferences, forKey: .references)
        }

        init(fileId: FileId, references: [InstanceId: NoteId]) {
            self.fileId = fileId
            self.references = references
        }
    }
    
    // MARK: - Properties
    
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
    
    // Note removed locally
    mutating func removeNote(_ note: Note) {
        notes.removeAll(where: { $0 == note })
    }
    
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
