//
//  BearAppCom.swift
//  BearSync
//
//  Created by d4Rk on 22.10.23.
//

import SwiftUI
import Combine

class BearCom {

    // MARK: - Properties

    @Preference(\.bearAPIToken) var bearAPIToken

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

    /// https://bear.app/faq/x-callback-url-scheme-documentation/#token-generation
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
        guard bearAPIToken != "" else { throw BearComError.bearAPITokenNotSet }

        let requestId = UUID()
        let queryItems = [URLQueryItem(name: "token", value: bearAPIToken),
                          URLQueryItem(name: "tag", value: tag),
                          URLQueryItem(name: "show_window", value: "no")]
        let url = URL(action: .search, requestId: requestId, queryItems: queryItems)!

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
        let queryItems = [URLQueryItem(name: "id", value: noteId),
                          URLQueryItem(name: "exclude_trashed", value: "yes"),
                          URLQueryItem(name: "show_window", value: "no"),
                          URLQueryItem(name: "open_note", value: "no")]
        let url = URL(action: .openNote, requestId: requestId, queryItems: queryItems)!
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
        let queryItems = [URLQueryItem(name: "text", value: text),
                          URLQueryItem(name: "open_note", value: "no"),
                          URLQueryItem(name: "show_window", value: "no")]
        let url = URL(action: .create, requestId: requestId, queryItems: queryItems)!
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
        let queryItems = [URLQueryItem(name: "id", value: noteId),
                          URLQueryItem(name: "text", value: text),
                          URLQueryItem(name: "mode", value: "replace_all"),
                          URLQueryItem(name: "open_note", value: "no"),
                          URLQueryItem(name: "show_window", value: "no")]
        let url = URL(action: .addText, requestId: requestId, queryItems: queryItems)!
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
        let queryItems = [URLQueryItem(name: "id", value: noteId),
                          URLQueryItem(name: "show_window", value: "no")]
        let url = URL(action: .trash, requestId: requestId, queryItems: queryItems)!
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

extension URL {
    init?(action: Action, requestId: UUID, queryItems: [URLQueryItem]) {
        var components = URLComponents()
        components.scheme = "bear"
        components.host = "x-callback-url"
        components.path = "/\(action.rawValue)"
        components.queryItems = queryItems

        guard var url = components.url else { return nil }

        var callbackComponents = URLComponents()
        callbackComponents.scheme = "bearsync"
        callbackComponents.host = "x-callback-url"
        callbackComponents.path = "/\(action.rawValue)"
        callbackComponents.queryItems = [URLQueryItem(name: "requestId", value: requestId.uuidString)]

        guard let callbackURL = callbackComponents.string else { return nil }

        url.append(queryItems: [URLQueryItem(name: "x-success", value: callbackURL),
                                URLQueryItem(name: "x-error", value: callbackURL)])

        self = url
    }
}
