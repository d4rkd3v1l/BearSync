//
//  BearAppSyncApp.swift
//  BearAppSync
//
//  Created by d4Rk on 04.10.23.
//

import SwiftUI

enum Status: String {
    case success
    case error
}

enum Action: String {
    case search
    case create
}

@main
struct BearAppSyncApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"]) // activate existing window if exists
                .onOpenURL(perform: { url in
                    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                          let action = Action(rawValue: url.lastPathComponent),
                          let rawStatus = components.queryItems?["status"],
                          let status = Status(rawValue: rawStatus) else { return }
                    
                    switch action {
                    case .search:
                        guard let tag = components.queryItems?["tag"],
                              let notes = components.queryItems?["notes"] else { fatalError("Not all needed parameters could be resolved.") }
                        
                        let searchNotes = try! JSONDecoder().decode([SearchNote].self, from: notes.data(using: .utf8)!)
                        
                        let userInfo = ["tag": tag, "notes": searchNotes as Any]
                        let notification = Notification(name: Notification.Name(Action.search.rawValue), object: nil, userInfo: userInfo)
                        NotificationCenter.default.post(notification)
                        
                    case .create:
                        switch status {
                        case .success:
                            guard let fileId = components.queryItems?["fileId"],
                                  let identifier = components.queryItems?["identifier"] else { fatalError("Not all needed parameters could be resolved.") }
                            
                            let userInfo = ["fileId": fileId, "identifier": identifier]
                            let notification = Notification(name: Notification.Name(Action.create.rawValue), object: nil, userInfo: userInfo)
                            NotificationCenter.default.post(notification)
                            
                        case .error:
                            fatalError("No error handling yet! TODO! \(url)")
                        }
                    }
                })
        }.commands {
            CommandGroup(replacing: .newItem, addition: { })
        }
        .handlesExternalEvents(matching: ["*"]) // create new window if doesn't exist
    }
}

// TODO: Post on SO? https://stackoverflow.com/questions/41421686/get-the-value-of-url-parameters
extension Array where Element == URLQueryItem {
    subscript(name: String) -> String? {
        self.first(where: { $0.name == name })?.value
    }
}
