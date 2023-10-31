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
            BearCom.shared.handleURL(url)
        }
    }
}

@main
struct BearAppSyncApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var icon = "arrow.triangle.2.circlepath"
    @State private var isSynchronizing = false
    
    var body: some Scene {
        MenuBarExtra("Bear App Sync", systemImage: icon) {
            Button("Synchronize") {
                Task {
                    icon = "clock.arrow.2.circlepath"
                    isSynchronizing = true
                    try await Synchronizer().synchronize()
                    isSynchronizing = false
                    icon = "arrow.triangle.2.circlepath"
                }
            }.keyboardShortcut("s")
            
            Divider()

            SettingsLink {
                 Text("Preferences...")
            }.keyboardShortcut(",")
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
        
        Settings {
            SettingsPane()
//            Text("Bear API Token")
//            Text("Tags")
//            Text("GitHub Token")
//            Text("GitHub Repo URL")
//            Text("Select Repo Folder")
        }
    }
}
struct SettingsPane: View {
    @AppStorage("preference_keyAsPerSettingBundleIdentifier") var kSetting = true
    var body: some View {
        Form {
            Toggle("Perform some boolean Setting", isOn: $kSetting)
                .help(kSetting ? "Undo that boolean Setting" : "Perform that boolean Setting")
        }
        .padding()
        .frame(minWidth: 400)
    }
}
