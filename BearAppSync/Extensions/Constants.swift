//
//  Constants.swift
//  BearAppSync
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
        case username = "BearAppSync"
        case mail = "bear@app.sync"
    }
}
