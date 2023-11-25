//
//  AppDelegate.swift
//  BearAppSync
//
//  Created by d4Rk on 25.11.23.
//

import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
    var didReceiveShowSettingsIntent: (() -> Void)? = nil

    func applicationWillFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            Synchronizer.shared.handleURL(url)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if response.actionIdentifier == NotificationManager.Action.showSettings.rawValue {
            didReceiveShowSettingsIntent?()
        }
    }
}
