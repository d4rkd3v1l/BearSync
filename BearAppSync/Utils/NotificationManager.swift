//
//  NotificationManager.swift
//  BearAppSync
//
//  Created by d4Rk on 25.11.23.
//

import UserNotifications

class NotificationManager {
    enum Category: String {
        case showSettings
    }

    enum Action: String {
        case showSettings
    }

    private let notificationCenter: UNUserNotificationCenter

    init(_ notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter

        Task {
            if try await requestAuthorization() {
                registerCategories()
            } else {
                // Error out
            }
        }
    }

    private func requestAuthorization() async throws -> Bool {
        let isAuthorized = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        return isAuthorized
    }

    private func registerCategories() {
        let settingsAction = UNNotificationAction(identifier: Action.showSettings.rawValue, title: "Show settings")
        let settingsCategory = UNNotificationCategory(identifier: Category.showSettings.rawValue, actions: [settingsAction], intentIdentifiers: [])
        notificationCenter.setNotificationCategories([settingsCategory])
    }

    func sendNotification(title: String, body: String, category: NotificationManager.Category? = nil) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        if let category {
            content.categoryIdentifier = category.rawValue
        }

        let request = UNNotificationRequest(identifier: "identifier", content: content, trigger: nil)
        try await notificationCenter.add(request)
    }
}
