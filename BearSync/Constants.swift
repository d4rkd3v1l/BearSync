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
        case bearAppSQLiteDBPathBookmark
    }

    enum PreferencesKey: String {
        case clientId
        case bearAPIToken
        case gitRepoURL
        case tags
        case useSQLite
    }

    enum AppIconName: String {
        case idle = "arrow.triangle.2.circlepath"
        case syncInProgress = "clock.arrow.2.circlepath"
        case syncError = "exclamationmark.arrow.triangle.2.circlepath"
    }
}
