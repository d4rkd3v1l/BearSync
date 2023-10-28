//
//  BearAppSyncApp.swift
//  BearAppSync
//
//  Created by d4Rk on 04.10.23.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            BearAppCom.shared.handleURL(url)
        }
    }
}

@main
struct BearAppSyncApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("a", systemImage: "arrow.triangle.2.circlepath") {
            Button("Synchronize") {
                Task {
                    try await synchronize()
                }
            }
            .keyboardShortcut("s")
            
            Divider()
            
            Button("Preferences...") {
                
            }
            .keyboardShortcut(",")
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
