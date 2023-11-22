//
//  Synchronizer.swift
//  BearAppSync
//
//  Created by d4Rk on 31.10.23.
//

import Foundation

enum SyncError: Error {
    case bearAPITokenNotSet
    case gitRepoURLNotSet
    case gitRepoPathNotSet
    case syncInProgress
}

class Synchronizer {
    
    // MARK: - Properties
    
    static let shared = Synchronizer(bearCom: BearCom())
    
    @Preference(\.bearAPIToken) var bearAPIToken
    @Preference(\.gitRepoURL) var gitRepoURL
    @Preference(\.tags) var tags

    private let bearCom: BearCom
    private var systemCom: SystemCom!
    private var syncInProgress = false
    
    // MARK: - Lifecycle
    
    init(bearCom: BearCom) {
        self.bearCom = bearCom
        
    }
    
    func handleURL(_ url: URL) {
        self.bearCom.handleURL(url)
    }
    
    // MARK: - Synchronize
    
    @MainActor
    func synchronize() async throws {
        
        guard bearAPIToken != "" else { throw SyncError.bearAPITokenNotSet }
        guard gitRepoURL != "" else { throw SyncError.gitRepoURLNotSet }
        guard let gitRepoPath = try? OpenPanelHelper().getURL(for: "gitRepoPathBookmark") else { throw SyncError.gitRepoPathNotSet }

        print("bearAPIToken \(bearAPIToken)")
        print("gitRepoURL \(gitRepoURL)")

        guard !syncInProgress else { throw SyncError.syncInProgress }
        syncInProgress = true
        
        print("Starting sync...")
        systemCom = SystemCom(currentDirectory: gitRepoPath)
        let mappingURL = gitRepoPath.appending(path: "mapping.json")
        var mapping = (try? Mapping.load(from: mappingURL)) ?? Mapping()
        let instanceId = InstanceId(uuidString: UserDefaults.standard.string(forKey: "instanceId") ?? InstanceId().uuidString) ?? InstanceId()
        UserDefaults.standard.set(instanceId.uuidString, forKey: "instanceId")
        
        print("Exporting local notes...")
        var bearNoteIds = try await noteIdsFromBear(for: tags)
        try await exportNotes(noteIds: bearNoteIds, for: instanceId, to: gitRepoPath, using: &mapping)

        print("Removing locally deleted notes...")
        try removeLocallyDeletedNotes(excludedNoteIds: bearNoteIds, for: instanceId, from: gitRepoPath, using: &mapping)

        try mapping.save(to: mappingURL)
        
        print("Fetching remote changes...")
        gitConfigure()
        gitCommit(message: "Updates from \(instanceId.uuidString)")
        gitPull()
        
        mapping = (try? Mapping.load(from: mappingURL)) ?? Mapping()
        
        print("Applying remote changes to local notes...")
        try await updateNotesFromRemote(for: instanceId, with: gitRepoPath, using: &mapping)

        print("Removing remotely deleted notes...")
        bearNoteIds = try await noteIdsFromBear(for: tags)
        try await removeRemotelyDeletedNotes(localNoteIds: bearNoteIds, using: mapping)
        
        try mapping.save(to: mappingURL)
        
        print("Pushing changes to remote...")
        gitCommit(message: "Additional updates from \(instanceId.uuidString)")
        gitPush()
        
        print("Done.")
        syncInProgress = false
    }
    
    // MARK: - Helper
    
    // MARK: Git
    private func gitConfigure() {
        systemCom.bash("git config user.name \"BearAppSync\"")
        systemCom.bash("git config user.email \"no@mail.address\"")
        systemCom.bash("git remote set-url origin \(gitRepoURL)")
    }
    
    private func gitCommit(message: String) {
        systemCom.bash("git add .")
        systemCom.bash("git commit -m \"\(message)\"")
    }
    
    private func gitPull() {
        let status = systemCom.bash("git pull --no-rebase")
        
        if status != 0 {
            // TODO: Send Notification?!
            print(">>>>> Error during pull, probably merge-conflict. Status: \(status)")

            // 1 = invalid repo url
        }
    }
    
    private func gitPush() {
        systemCom.bash("git push")
    }
    
    private func noteIdsFromBear(for tags: [String]) async throws -> [NoteId] {
        var allNoteIds: [NoteId] = []
        for tag in tags {
            let searchResult = try await bearCom.search(tag: tag)
            let noteIds = searchResult.notes.map({ $0.identifier })
            allNoteIds.append(contentsOf: noteIds)
        }
        return allNoteIds
    }
    
    // MARK: Notes
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
    
    private func removeLocallyDeletedNotes(excludedNoteIds: [NoteId],
                                           for instanceId: InstanceId,
                                           from baseURL: URL,
                                           using mapping: inout Mapping) throws {
        for note in mapping.notes {
            if let fileNoteId = note.references[instanceId] {
                if !excludedNoteIds.contains(fileNoteId) {
                    print("Note was deleted locally... Removing it from repo \(note.fileId)")
                    let filename = baseURL.appending(component: note.fileId.uuidString)
                    try FileManager.default.removeItem(at: filename)
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
    
    private func removeRemotelyDeletedNotes(localNoteIds: [NoteId], using mapping: Mapping) async throws {
        for noteId in localNoteIds {
            if mapping.notes.contains(where: { $0.references.contains(where: { $0.value == noteId }) }) {
                print("Note still exists remotely... Skipping \(noteId)")
            } else {
                print("Note was deleted remotely... Removing it locally \(noteId)")
                _ = try await bearCom.trash(noteId: noteId)
            }
        }
    }
}
