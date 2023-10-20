//
//  OpenPanelHelper.swift
//  BearAppSync
//
//  Created by d4Rk on 13.10.23.
//

import SwiftUI

@MainActor
class OpenPanelHelper {
    enum Error: Swift.Error {
        case openFailed
        case bookmarkNoAccess
        case bookmarkStale
    }
    
    enum Kind {
        case file
        case directory
        
        var prompt: String {
            switch self {
            case .file:
                return "Select File"
                
            case .directory:
                return "Select Directory"
            }
        }
    }
    
    func openFile(at url: URL?, bookmark: String) async throws -> URL {
        try await open(at: url, bookmark: bookmark, kind: .file)
    }
    
    func openDirectory(at url: URL?, bookmark: String) async throws -> URL {
        try await open(at: url, bookmark: bookmark, kind: .directory)
    }
    
    private func open(at url: URL?, bookmark: String, kind: Kind) async throws -> URL {
        if let bookmarkData = UserDefaults.standard.data(forKey: bookmark) {
            var isStale = false
            let bookmarkUrl = try URL(resolvingBookmarkData: bookmarkData, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale);
            
            if(!isStale) {
                if(bookmarkUrl.startAccessingSecurityScopedResource()) {
                    defer { bookmarkUrl.stopAccessingSecurityScopedResource() }
                    return bookmarkUrl
                } else {
                    UserDefaults.standard.set(nil, forKey: bookmark)
                    throw Error.bookmarkNoAccess
                }
            } else {
                UserDefaults.standard.set(nil, forKey: bookmark)
                throw Error.bookmarkStale
            }
        } else {
            let openPanel = NSOpenPanel()
            openPanel.prompt = kind.prompt
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseDirectories = kind == .directory
            openPanel.canCreateDirectories = false
            openPanel.canChooseFiles = kind == .file
            openPanel.directoryURL = url
            
            let result = await openPanel.begin()
            guard result == .OK else { throw Error.openFailed }
            
            let bookmarkData = try openPanel.urls.first!.bookmarkData(options: []) // .securityScopeAllowOnlyReadAccess
            UserDefaults.standard.set(bookmarkData, forKey: bookmark)
            
            var isStale = false
            let bookmarkUrl = try URL(resolvingBookmarkData: bookmarkData, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale);
            return bookmarkUrl
        }
    }
}
