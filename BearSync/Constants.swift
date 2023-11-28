//
//  Constants.swift
//  BearSync
//
//  Created by d4Rk on 22.11.23.
//

import Foundation

struct Constants {
    enum UserDefaultsKey: String {
        case gitRepoPathBookmark
    }

    enum PreferencesKey: String {
        case instanceId
        case bearAPIToken
        case gitRepoURL
        case tags
    }

    enum GitConfig: String {
        case username = "BearSync"
        case mail = "be@r.sync"
    }

    enum AppIconName: String {
        case idle = "arrow.triangle.2.circlepath"
        case syncInProgress = "clock.arrow.2.circlepath"
        case syncError = "exclamationmark.arrow.triangle.2.circlepath"
    }
}
