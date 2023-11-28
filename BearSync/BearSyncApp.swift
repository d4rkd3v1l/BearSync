//
//  BearSyncApp.swift
//  BearSync
//
//  Created by d4Rk on 04.10.23.
//

import SwiftUI
import KeychainAccess
import UserNotifications

@main
struct BearSyncApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var icon = Constants.AppIconName.idle.rawValue
    @State private var settingsWindow: NSWindow?

    private let openSettingsAction = TriggerButtonAction()
    private let notificationManager = NotificationManager()

    var body: some Scene {
        MenuBarExtra("Bear Sync", systemImage: icon) {
            Button("Synchronize") {
                Task {
                    appDelegate.didReceiveShowSettingsIntent = {
                        Task { @MainActor in
                            try openSettingsAction()
                        }
                    }
                    do {
                        icon = Constants.AppIconName.syncInProgress.rawValue
                        try await Synchronizer.shared.synchronize()
                        icon = Constants.AppIconName.idle.rawValue
                    } catch {
                        if let syncError = error as? SyncError {
                            switch syncError {
                            case .bearAPITokenNotSet:
                                icon = Constants.AppIconName.syncError.rawValue
                                try await notificationManager.sendNotification(title: "Bear API Token not set",
                                                                               body: "Please provide your Bear API Token in settings.",
                                                                               category: .showSettings)

                            case .gitRepoURLNotSet:
                                icon = Constants.AppIconName.syncError.rawValue
                                try await notificationManager.sendNotification(title: "Git Repo URL not set",
                                                                               body: "Please provide your git repo URL in settings.",
                                                                               category: .showSettings)

                            case .gitRepoPathNotSet:
                                icon = Constants.AppIconName.syncError.rawValue
                                try await notificationManager.sendNotification(title: "Git repo path not set",
                                                                               body: "Please provide the path to the git repo in settings.",
                                                                               category: .showSettings)

                            case .syncInProgress:
                                icon = Constants.AppIconName.syncInProgress.rawValue
                                try await notificationManager.sendNotification(title: "Sync already in progress",
                                                                               body: "Please wait until the current sync finished.")
                            }
                        }
                    }
                }
            }
            .keyboardShortcut("s")

            Divider()

            SettingsLink {
                 Text("Preferences...")
            }
            .keyboardShortcut(",")
            .buttonStyle(TriggerButtonStyle(trigger: openSettingsAction.binding))

            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Settings {
            SettingsView()
                .background(WindowAccessor(window: $settingsWindow))
                .onChange(of: settingsWindow) { oldWindow, newWindow in
                    newWindow?.level = .floating
                }
        }
    }
}
