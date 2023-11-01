//
//  BearAppCom.swift
//  BearAppSync
//
//  Created by d4Rk on 22.10.23.
//

import SwiftUI
import Combine


class BearCom {
    
    // MARK: - Properties
    
    static let shared = BearCom()
    
    private let urlOpener: URLOpener
    private let responseSubject = PassthroughSubject<Response, Never>()
    private var responses: AsyncStream<Response> {
        AsyncStream(bufferingPolicy: .bufferingOldest(0)) { continuation in
            let cancellable = self.responseSubject.sink { continuation.yield($0) }
            continuation.onTermination = { continuation in
                cancellable.cancel()
            }
        }
    }
    
    // MARK: - Lifecycle
    
    init(urlOpener: URLOpener = NSWorkspace.shared) {
        self.urlOpener = urlOpener
    }
    
    /// This must be called from whereever you receive callback urls, e.g. from `AppDelegte`.
    func handleURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let action = Action(rawValue: url.lastPathComponent) else { return }
        
        let response = Response(action.responseType, queryItems: components.queryItems!)!
        responseSubject.send(response)
    }
    
    // MARK: - Actions

    func search(tag: String) async throws -> SearchResult {
        let requestId = UUID()
        let url = URL(string: "bear://x-callback-url/search?token=\(bearAPIToken)&tag=\(tag)&show_window=no&x-success=bearappsync://x-callback-url/search?requestId%3d\(requestId)&x-error=bearappsync://x-callback-url/search?requestId%3d\(requestId)")!
        urlOpener.open(url)
        
        for await response in responses {
            if response.requestId == requestId {
                switch response.result {
                case .success(let result):
                    return result as! SearchResult
                    
                case .failure(let error):
                    throw error
                }
            }
        }
        
        fatalError("Should never get here?!")
    }
    
    func openNote(_ noteId: NoteId) async throws -> OpenNoteResult {
        let requestId = UUID()
        let url = URL(string: "bear://x-callback-url/open-note?id=\(noteId)&exclude_trashed=yes&show_window=no&open_note=no&x-success=bearappsync://x-callback-url/open-note?requestId%3d\(requestId)&x-error=bearappsync://x-callback-url/open-note?requestId%3d\(requestId)")!
        urlOpener.open(url)

        for await response in responses {
            if response.requestId == requestId {
                switch response.result {
                case .success(let result):
                    return result as! OpenNoteResult
                    
                case .failure(let error):
                    throw error
                }
            }
        }
        
        fatalError("Should never get here?!")
    }
    
    func create(with text: String) async throws -> CreateResult {
        let requestId = UUID()
        let textPercentEncoded = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let url = URL(string: "bear://x-callback-url/create?text=\(textPercentEncoded)&open_note=no&show_window=no&x-success=bearappsync://x-callback-url/create?requestId%3d\(requestId)&x-error=bearappsync://x-callback-url/create?requestId%3d\(requestId)")!
        urlOpener.open(url)

        for await response in responses {
            if response.requestId == requestId {
                switch response.result {
                case .success(let result):
                    return result as! CreateResult
                    
                case .failure(let error):
                    throw error
                }
            }
        }

        fatalError("Should never get here?!")
    }
    
    func addText(_ text: String, to noteId: NoteId) async throws -> AddTextResult {
        let requestId = UUID()
        let textPercentEncoded = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let url = URL(string: "bear://x-callback-url/add-text?id=\(noteId)&text=\(textPercentEncoded)&mode=replace_all&open_note=no&show_window=no&x-success=bearappsync://x-callback-url/add-text?requestId%3d\(requestId)&x-error=bearappsync://x-callback-url/add-text?requestId%3d\(requestId)")!
        urlOpener.open(url)
        
        for await response in responses {
            if response.requestId == requestId {
                switch response.result {
                case .success(let result):
                    return result as! AddTextResult
                    
                case .failure(let error):
                    throw error
                }
            }
        }
        
        fatalError("Should never get here?!")
    }
    
    func trash(noteId: NoteId) async throws -> TrashResult {
        let requestId = UUID()
        let url = URL(string: "bear://x-callback-url/trash?id=\(noteId)&show_window=no&x-success=bearappsync://x-callback-url/trash?requestId%3d\(requestId)&x-error=bearappsync://x-callback-url/trash?requestId%3d\(requestId)")!
        urlOpener.open(url)
        
        for await response in responses {
            if response.requestId == requestId {
                switch response.result {
                case .success(let result):
                    return result as! TrashResult
                    
                case .failure(let error):
                    throw error
                }
            }
        }
        
        fatalError("Should never get here?!")
    }
}
