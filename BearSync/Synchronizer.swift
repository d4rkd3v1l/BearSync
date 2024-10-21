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

    @Preference(\.clientId) var clientId
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
        let clientId = ClientId(uuidString: self.clientId) ?? ClientId()
        self.clientId = clientId.uuidString

        guard bearAPIToken != "" else { throw SyncError.bearAPITokenNotSet }
        guard gitRepoURL != "" else { throw SyncError.gitRepoURLNotSet }
        guard let gitRepoPath = try? OpenPanelHelper().getURL(for: Constants.UserDefaultsKey.gitRepoPathBookmark.rawValue) else { throw SyncError.gitRepoPathNotSet }

        guard !syncInProgress else { throw SyncError.syncInProgress }
        syncInProgress = true

        systemCom = SystemCom(currentDirectory: gitRepoPath)
        logger = Logger(logFile: gitRepoPath.appending(component: "sync.log"))

        try logger.log("--- Starting sync with tags: \(tags.map({ "#\($0)" }).joined(separator: " ")) ---")

        try logger.log("[1] Exporting local notes...")
        let localNoteIds = try await noteIdsFromBear(for: tags)
        var localNotes = try await notesFromBear(for: localNoteIds)
        try await exportNotes(notes: localNotes, to: gitRepoPath)

        try logger.log("[2] Removing locally deleted notes...")
        localNotes = try await notesFromBear(for: localNoteIds)
        try removeLocallyDeletedNotes(localNotes: localNotes, from: gitRepoPath)

        try logger.log("[3] Fetching remote changes...")
        gitConfigure()
        gitCommit(message: "Updates from \(clientId.uuidString)")
        gitPull()

        try logger.log("[4] Applying remote changes to local notes...")
        try await updateNotesFromRemote(localNotes: localNotes, with: gitRepoPath)

        try logger.log("[5] Removing remotely deleted notes...")
        localNotes = try await notesFromBear(for: localNoteIds) // TODO: Check if notes actually must be reloaded here.
        try await removeRemotelyDeletedNotes(localNotes: localNotes, with: gitRepoPath)

        try logger.log("[6] Pushing changes to remote...")
        gitCommit(message: "Additional updates from \(clientId.uuidString)")
        gitPush()

        try logger.log("[7] Done.")
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

    private func notesFromBear(for noteIds: [NoteId]) async throws -> [OpenNoteResult] {
        var results: [OpenNoteResult] = []
        for noteId in noteIds {
            let result: OpenNoteResult
            if useSQLite {
                result = try await sqliteCom.openNote(noteId)
            } else {
                result = try await bearCom.openNote(noteId)
            }
            results.append(result)
        }

        return results
    }

    private func exportNotes(notes: [OpenNoteResult],
                             to baseURL: URL) async throws {
        for openNoteResult in notes {
            let fileId: FileId
            let note: String

            if let existingFileId = openNoteResult.fileId {
                fileId = existingFileId
                note = openNoteResult.note
                try logger.log("\(fileId) will be exported...", indentationLevel: 2)
            } else {
                fileId = FileId()
                let trimmedNote = openNoteResult.note.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let text = "\(trimmedNote)\n\n[BearSync FileId]: <> (\(fileId.uuidString))\n"
                let addTextResult = try await bearCom.replaceAllText(text, for: openNoteResult.identifier)
                note = addTextResult.note
                try logger.log("\(fileId) will be exported for the first time...", indentationLevel: 2)
            }

            let filename = baseURL.appending(component: fileId.uuidString)
            try note.write(to: filename, atomically: true, encoding: .utf8)
        }
    }
    
    private func removeLocallyDeletedNotes(localNotes: [OpenNoteResult],
                                           from baseURL: URL) throws {
        let fileIds = try FileManager.default.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil)
            .map { $0.lastPathComponent }
            .compactMap { FileId(uuidString: $0) }

        for fileId in fileIds {
            if !localNotes.contains(where: { $0.fileId == fileId }) {
                let filename = baseURL.appending(component: fileId.uuidString)
                try FileManager.default.removeItem(at: filename)
                try logger.log("\(fileId) was deleted locally. Removing note from repo...", indentationLevel: 2)
            } else {
                try logger.log("\(fileId) still exists locally. Skipping...", indentationLevel: 2)
            }
        }
    }
    
    private func updateNotesFromRemote(localNotes: [OpenNoteResult],
                                       with baseURL: URL) async throws {
        let fileIds = try FileManager.default.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil)
            .map { $0.lastPathComponent }
            .compactMap { FileId(uuidString: $0) }

        for fileId in fileIds {
            let text = try String(contentsOf: baseURL.appending(component: fileId.uuidString))

            if let openNoteResult = localNotes.first(where: { $0.fileId == fileId }) { // Update
                if openNoteResult.note.sha256 != text.sha256 {
                    try logger.log("\(fileId) changed remotely. Applying changes...", indentationLevel: 2)
                    _ = try await bearCom.replaceAllText(text, for: openNoteResult.identifier)
                } else {
                    try logger.log("\(fileId) unchanged. Skipping...", indentationLevel: 2)
                }
            } else { // Create
                try logger.log("\(fileId) was created remotely. Adding note locally...", indentationLevel: 2)
                _ = try await bearCom.create(with: text)
            }
        }
    }

    private func removeRemotelyDeletedNotes(localNotes: [OpenNoteResult],
                                            with baseURL: URL) async throws {
        let fileIds = try FileManager.default.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil)
            .map { $0.lastPathComponent }
            .compactMap { FileId(uuidString: $0) }

        for localNote in localNotes {
            guard let fileId = localNote.fileId else {
                try logger.log(">>>>> ERROR: Note does not have a fileId... At this point any local note should have one... SNAFU -.-")
                continue
            }

            if fileIds.contains(fileId) {
                try logger.log("\(fileId) still exists remotely. Skipping...", indentationLevel: 2)
            } else {
                try logger.log("\(fileId) was deleted remotely. Removing it locally...", indentationLevel: 2)
                _ = try await bearCom.trash(noteId: localNote.identifier)
            }
        }
    }
}
