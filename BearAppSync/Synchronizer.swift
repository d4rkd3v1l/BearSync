//
//  Synchronizer.swift
//  BearAppSync
//
//  Created by d4Rk on 31.10.23.
//

import Foundation

private let tags = ["test", "test2"]

enum SyncError: Error {
    case syncInProgress
}

class Synchronizer {
    private let bearCom: BearCom
    private var syncInProgress = false
    
    // MARK: - Lifecycle
    
    init(bearCom: BearCom = BearCom.shared) {
        self.bearCom = bearCom
    }
    
    // MARK: - Synchronize
    
    @MainActor
    func synchronize() async throws {
        guard !syncInProgress else { throw SyncError.syncInProgress }
        syncInProgress = true
        
        print("Starting sync...")
        let openPanelHelper = OpenPanelHelper()
        let gitRepoURL = try await openPanelHelper.openDirectory(at: nil, bookmark: "gitRepoPathBookmark")
        let mappingURL = gitRepoURL.appending(path: "mapping.json")
        var mapping = (try? Mapping.load(from: mappingURL)) ?? Mapping()
        let instanceId = InstanceId(uuidString: UserDefaults.standard.string(forKey: "instanceId") ?? InstanceId().uuidString) ?? InstanceId()
        UserDefaults.standard.set(instanceId.uuidString, forKey: "instanceId")
        
        print("Exporting local notes...")
        var bearNoteIds = try await noteIdsFromBear(for: tags)
        try await exportNotes(noteIds: bearNoteIds, for: instanceId, to: gitRepoURL, using: &mapping)
        
        print("Removing locally deleted notes...")
        try removeNotes(excludedNoteIds: bearNoteIds, for: instanceId, from: gitRepoURL, using: &mapping)
        
        try mapping.save(to: mappingURL)
        
        print("Fetching remote changes...")
        SystemCom.bash(currentDirectory: gitRepoURL, "git config user.name \"BearAppSync\"")
        SystemCom.bash(currentDirectory: gitRepoURL, "git config user.email \"no@mail.address\"")
        SystemCom.bash(currentDirectory: gitRepoURL, "git config pull.rebase false")
        SystemCom.bash(currentDirectory: gitRepoURL, "git remote set-url origin https://\(gitHubToken)@github.com/d4rkd3v1l/bear-sync.git")
        SystemCom.bash(currentDirectory: gitRepoURL, "git add .")
        SystemCom.bash(currentDirectory: gitRepoURL, "git commit -m \"Updates from \(instanceId.uuidString)\"")
        SystemCom.bash(currentDirectory: gitRepoURL, "git pull")
        
        mapping = (try? Mapping.load(from: mappingURL)) ?? Mapping()
        
        print("Applying remote changes to local notes...")
        try await updateNotesFromRemote(for: instanceId, with: gitRepoURL, using: &mapping)
        
        print("Removing remotely deleted notes...")
        bearNoteIds = try await noteIdsFromBear(for: tags)
        for noteId in bearNoteIds {
            if mapping.notes.contains(where: { $0.references.contains(where: { $0.value == noteId }) }) {
                print("Note still exists remotely... Skipping \(noteId)")
            } else {
                print("Note was deleted remotely... Removing it locally \(noteId)")
                _ = try await bearCom.trash(noteId: noteId)
            }
        }
        
        try mapping.save(to: mappingURL)
        
        print("Pushing notes to remote...")
        SystemCom.bash(currentDirectory: gitRepoURL, "git add .")
        SystemCom.bash(currentDirectory: gitRepoURL, "git commit -m \"Additional updates from \(instanceId.uuidString)\"")
        SystemCom.bash(currentDirectory: gitRepoURL, "git push")
        
        print("Done.")
        syncInProgress = false
    }
    
    // MARK: - Helper
    
    private func noteIdsFromBear(for tags: [String]) async throws -> [NoteId] {
        var allNoteIds: [NoteId] = []
        for tag in tags {
            let searchResult = try await bearCom.search(tag: tag)
            let noteIds = searchResult.notes.map({ $0.identifier })
            allNoteIds.append(contentsOf: noteIds)
        }
        return allNoteIds
    }
    
    private func exportNotes(noteIds: [NoteId],
                             for instanceId: InstanceId,
                             to baseURL: URL,
                             using mapping: inout Mapping) async throws {
        for noteId in noteIds {
            let openNoteResult = try await bearCom.openNote(noteId)
            let fileId = mapping.fileId(for: openNoteResult.identifier, in: instanceId) ?? mapping.addNote(with: openNoteResult.identifier, for: instanceId)
            
            let filename = baseURL.appending(component: fileId.uuidString)
            try openNoteResult.note.write(to: filename, atomically: true, encoding: .utf8)
        }
    }
    
    private func removeNotes(excludedNoteIds: [NoteId],
                             for instanceId: InstanceId,
                             from baseURL: URL,
                             using mapping: inout Mapping) throws {
        for note in mapping.notes {
            if let fileNoteId = note.references[instanceId] {
                if !excludedNoteIds.contains(fileNoteId) {
                    print("Note was deleted locally... Removing it from repo \(note.fileId)")
                    let filename = baseURL.appending(component: note.fileId.uuidString)
                    try FileManager.default.removeItem(at: filename)
//                    mapping.removeNote(with: note.fileId, for: instanceId)
                    mapping.removeNote(note)
                } else {
                    print("Note still exists locally... Skipping \(note.fileId)")
                }
            } else {
                fatalError("Mapping in invalid state! Probably sync was broken before...")
            }
        }
    }
    
    private func updateNotesFromRemote(for instanceId: InstanceId,
                                       with baseURL: URL,
                                       using mapping: inout Mapping) async throws {
        for note in mapping.notes {
//            if note.isDeleted {
//                print("Note was remotely deleted \(note.fileId)")
//                mapping.removeNote(with: note.fileId, for: instanceId)
//                // TODO: BearCom.trash
//            } else 
            if let noteId = note.references[instanceId] {  // Update
                let text = try String(contentsOf: baseURL.appending(component: note.fileId.uuidString))
                let openNoteResult = try? await bearCom.openNote(noteId)
                if openNoteResult?.note.sha256 != text.sha256 {
                    print("Note changed... Updating \(note.fileId)")
                    _ = try await bearCom.addText(text, to: noteId)
                } else {
                    print("Note unchanged... Skipping \(note.fileId)")
                }
            } else { // Create
                print("New note... Creating \(note.fileId)")
                let text = try String(contentsOf: baseURL.appending(component: note.fileId.uuidString))
                guard let noteId = try? await bearCom.create(with: text).identifier,
                      mapping.addReference(to: note.fileId, noteId: noteId, instanceId: instanceId) else {
                    fatalError("Could not add reference to note!")
                }
            }
        }
    }
}
