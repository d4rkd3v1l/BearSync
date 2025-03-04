//
//  BearSyncApp.swift
//  BearSync
//
//  Created by d4Rk on 04.10.23.
//

import SwiftUI
import KeychainAccess
import UserNotifications

enum Status {
    case idle
    case syncInProgress(progress: Double)
    case syncError
    case done

    var icon: String {
        switch self {
        case .idle: "arrow.trianglehead.2.counterclockwise.rotate.90"
        case .syncInProgress: "clock.arrow.trianglehead.2.counterclockwise.rotate.90"
        case .syncError: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
        case .done: "checkmark.circle"
        }
    }

    var progress: String {
        switch self {
        case .idle: "Idle"
        case .syncInProgress(let progress): "Synchronizing... \(Int((progress*100).rounded()))%"
        case .syncError: "Error"
        case .done: "Finished"
        }
    }
}

@main
struct BearSyncApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var status = Status.idle
    @State private var settingsWindow: NSWindow?

    private let openSettingsAction = TriggerButtonAction()
    private let notificationManager = NotificationManager()

    var body: some Scene {
        MenuBarExtra("Bear Sync", systemImage: status.icon) {
            Text("Status: \(status.progress)")

            Button("Synchronize") {
                synchronize()
            }
            .keyboardShortcut("s")

            Divider()

            if #available(macOS 14.0, *) {
                SettingsLink {
                    Text("Preferences...")
                }
                .keyboardShortcut(",")
                .buttonStyle(TriggerButtonStyle(trigger: openSettingsAction.binding))
            } else {
                Button(action: {
                    if #available(macOS 13.0, *) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } else {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                    }
                }, label: {
                    Text("Preferences...")
                })
                .keyboardShortcut(",")
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Settings {
            if #available(macOS 14.0, *) {
                SettingsView()
                    .background(WindowAccessor(window: $settingsWindow))
                    .onChange(of: settingsWindow) { oldWindow, newWindow in
                        newWindow?.level = .floating
                    }
            } else {
                SettingsView()
            }
        }
    }

    private func synchronize() {
        Task {
            appDelegate.didReceiveShowSettingsIntent = {
                if #available(macOS 14.0, *) {
                    Task {
                        try openSettingsAction()
                    }
                } else {
                    if #available(macOS 13.0, *) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } else {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                    }
                }
            }

            do {
                status = .syncInProgress(progress: 0)
                try await Synchronizer.shared.synchronize() { progress in
                    if progress == 1.0 {
                        status = .done
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            status = .idle
                        }
                    } else {
                        status = .syncInProgress(progress: progress)
                    }
                }
            } catch {
                if let syncError = error as? SyncError {
                    switch syncError {
                    case .clientIdNotSet:
                        status = .syncError
                        try await notificationManager.sendNotification(title: "Client name not set",
                                                                       body: "Please provide a client name in settings.",
                                                                       category: .showSettings)

                    case .bearAPITokenNotSet:
                        status = .syncError
                        try await notificationManager.sendNotification(title: "Bear API Token not set",
                                                                       body: "Please provide your Bear API Token in settings.",
                                                                       category: .showSettings)

                    case .gitRepoURLNotSet:
                        status = .syncError
                        try await notificationManager.sendNotification(title: "Git Repo URL not set",
                                                                       body: "Please provide your git repo URL in settings.",
                                                                       category: .showSettings)

                    case .gitRepoPathNotSet:
                        status = .syncError
                        try await notificationManager.sendNotification(title: "Git repo path not set",
                                                                       body: "Please provide the path to the git repo in settings.",
                                                                       category: .showSettings)

                    case .syncInProgress:
                        status = .syncError
                        try await notificationManager.sendNotification(title: "Sync already in progress",
                                                                       body: "Please wait until the current sync finished.")
                    }
                }
            }
        }
    }
}
