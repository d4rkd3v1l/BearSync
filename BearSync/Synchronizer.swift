//
//  Synchronizer.swift
//  BearSync
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
    
    static let shared = Synchronizer(bearCom: BearCom(), sqliteCom: SQLiteCom(pathProvider: pathProvider))

    @Preference(\.instanceId) var instanceId
    @Preference(\.bearAPIToken) var bearAPIToken
    @Preference(\.gitRepoURL) var gitRepoURL
    @Preference(\.tags) var tags
    @Preference(\.useSQLite) var useSQLite

    private let bearCom: BearCom
    private let sqliteCom: SQLiteCom
    private var systemCom: SystemCom!
    private var logger: Logger!
    private var syncInProgress = false

    // MARK: - Lifecycle
    
    init(bearCom: BearCom, sqliteCom: SQLiteCom) {
        self.bearCom = bearCom
        self.sqliteCom = sqliteCom
    }

    private static func pathProvider() async throws -> String {
        let bearDBFilePath = ("~/Library/Group Containers/9K33E3U3T4.net.shinyfrog.bear/Application Data/database.sqlite" as NSString).expandingTildeInPath

        if let url = try? OpenPanelHelper().getURL(for: Constants.UserDefaultsKey.bearAppSQLiteDBPathBookmark.rawValue) {
            return url.path(percentEncoded: false)
        }

        let url = try await OpenPanelHelper().openFile(at: NSURL.fileURL(withPath: bearDBFilePath), bookmark: Constants.UserDefaultsKey.bearAppSQLiteDBPathBookmark.rawValue)
        return url.path(percentEncoded: false)
    }

    // MARK: - Public API

    func handleURL(_ url: URL) {
        self.bearCom.handleURL(url)
    }
    
    // MARK: - Synchronize
    
    @MainActor
    func synchronize() async throws {
        let instanceId = InstanceId(uuidString: self.instanceId) ?? InstanceId()
        self.instanceId = instanceId.uuidString

        guard bearAPIToken != "" else { throw SyncError.bearAPITokenNotSet }
        guard gitRepoURL != "" else { throw SyncError.gitRepoURLNotSet }
        guard let gitRepoPath = try? OpenPanelHelper().getURL(for: Constants.UserDefaultsKey.gitRepoPathBookmark.rawValue) else { throw SyncError.gitRepoPathNotSet }

        guard !syncInProgress else { throw SyncError.syncInProgress }
        syncInProgress = true

        systemCom = SystemCom(currentDirectory: gitRepoPath)
        logger = Logger(logFile: gitRepoPath.appending(component: "sync.log"))

        try logger.log("--- Starting sync with tags: \(tags.map({ "#\($0)" }).joined(separator: " ")) ---")
        let mappingURL = gitRepoPath.appending(path: "mapping.json")
        var mapping = (try? Mapping.load(from: mappingURL)) ?? Mapping()

        try logger.log("Exporting local notes...")
        var bearNoteIds = try await noteIdsFromBear(for: tags)
        try await exportNotes(noteIds: bearNoteIds, for: instanceId, to: gitRepoPath, using: &mapping)

        try logger.log("Removing locally deleted notes...")
        try removeLocallyDeletedNotes(excludedNoteIds: bearNoteIds, for: instanceId, from: gitRepoPath, using: &mapping)

        try mapping.save(to: mappingURL)

        try logger.log("Fetching remote changes...")
        gitConfigure()
        gitCommit(message: "Updates from \(instanceId.uuidString)")
        gitPull()
        
        mapping = (try? Mapping.load(from: mappingURL)) ?? Mapping()

        try logger.log("Applying remote changes to local notes...")
        try await updateNotesFromRemote(for: instanceId, with: gitRepoPath, using: &mapping)

        try logger.log("Removing remotely deleted notes...")
        bearNoteIds = try await noteIdsFromBear(for: tags)
        try await removeRemotelyDeletedNotes(localNoteIds: bearNoteIds, for: instanceId, using: mapping)

        try mapping.save(to: mappingURL)

        try logger.log("Pushing changes to remote...")
        gitCommit(message: "Additional updates from \(instanceId.uuidString)")
        gitPush()

        try logger.log("Done.")
        syncInProgress = false
    }
    
    // MARK: - Helper
    
    // MARK: Git
    private func gitConfigure() {
        systemCom.bash("git config user.name \"\(Constants.GitConfig.username.rawValue)\"")
        systemCom.bash("git config user.email \"\(Constants.GitConfig.mail.rawValue)\"")
        systemCom.bash("git remote set-url origin \(gitRepoURL)")
        systemCom.bash("echo \".DS_Store\nsync.log\n\" > .gitignore")
    }
    
    private func gitCommit(message: String) {
        systemCom.bash("git add .")
        systemCom.bash("git commit -m \"\(message)\"")
    }
    
    private func gitPull() {
        let status = systemCom.bash("git pull --no-rebase")
        
        if status != 0 {
            try? logger.log(">>>>> Error during pull, probably merge-conflict. Status: \(status)")
            // TODO: Send Notification?!

            // 1 = invalid repo url
        }
    }
    
    private func gitPush() {
        systemCom.bash("git push")
    }

    // MARK: Notes
    private func noteIdsFromBear(for tags: [String]) async throws -> [NoteId] {
        var allNoteIds: [NoteId] = []
        for tag in tags {
            let searchResult: SearchResult?
            if useSQLite {
                searchResult = try? await sqliteCom.search(tag: tag)
            } else {
                searchResult = try? await bearCom.search(tag: tag)
            }
            if let noteIds = searchResult?.notes.map({ $0.identifier }) {
                allNoteIds.append(contentsOf: noteIds)
            }
        }
        return allNoteIds
    }

    private func exportNotes(noteIds: [NoteId],
                             for instanceId: InstanceId,
                             to baseURL: URL,
                             using mapping: inout Mapping) async throws {
        for noteId in noteIds {
            let openNoteResult: OpenNoteResult
            if useSQLite {
                openNoteResult = try await sqliteCom.openNote(noteId)
            } else {
                openNoteResult = try await bearCom.openNote(noteId)
            }

            let fileId = mapping.fileId(for: openNoteResult.identifier, in: instanceId) ?? mapping.addNote(with: openNoteResult.identifier, for: instanceId)
            try logger.log("Exporting note with fileId \(fileId)...")

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
                    try logger.log("Note with fileId \(note.fileId) was deleted locally. Removing it from repo...")
                    let filename = baseURL.appending(component: note.fileId.uuidString)
                    try FileManager.default.removeItem(at: filename)
                    mapping.removeNote(note)
                } else {
                    try logger.log("Note with fileId \(note.fileId) still exists locally. Skipping...")
                }
            } else {
                try logger.log("Note with fileId \(note.fileId) does not exist yet locally. Will be added later...")
            }
        }
    }
    
    private func updateNotesFromRemote(for instanceId: InstanceId,
                                       with baseURL: URL,
                                       using mapping: inout Mapping) async throws {
        for note in mapping.notes {
            if let noteId = note.references[instanceId] {  // Update
                let text = try String(contentsOf: baseURL.appending(component: note.fileId.uuidString))
                let openNoteResult: OpenNoteResult
                if useSQLite {
                    openNoteResult = try await sqliteCom.openNote(noteId)
                } else {
                    openNoteResult = try await bearCom.openNote(noteId)
                }

                if openNoteResult.note.sha256 != text.sha256 {
                    try logger.log("Note with fileId \(note.fileId) changed remotely. Applying changes...")
                    _ = try await bearCom.addText(text, to: noteId)
                } else {
                    try logger.log("Note with fileId \(note.fileId) unchanged. Skipping...")
                }
            } else { // Create
                try logger.log("New note with fileId  \(note.fileId) created remotely. Adding note locally...")
                let text = try String(contentsOf: baseURL.appending(component: note.fileId.uuidString))
                guard let noteId = try? await bearCom.create(with: text).identifier,
                      mapping.addReference(to: note.fileId, noteId: noteId, instanceId: instanceId) else {
                    assertionFailure("Could not add reference to note!")
                    try logger.log("ERROR: Could not add note with fileId \(note.fileId) locally!")
                    return
                }
            }
        }
    }
    
    private func removeRemotelyDeletedNotes(localNoteIds: [NoteId], 
                                            for instanceId: InstanceId,
                                            using mapping: Mapping) async throws {
        for noteId in localNoteIds {
            let fileId = mapping.fileId(for: noteId, in: instanceId)

            if mapping.notes.contains(where: { $0.references.contains(where: { $0.value == noteId }) }) {
                try logger.log("Note with fileId \(fileId?.uuidString ?? noteId) still exists remotely. Skipping...")
            } else {
                try logger.log("Note with fileId \(fileId?.uuidString ?? noteId) was deleted remotely. Removing it locally...")
                _ = try await bearCom.trash(noteId: noteId)
            }
        }
    }
}
