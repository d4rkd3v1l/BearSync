//
//  Preferences.swift
//  BearSync
//
//  Created by d4Rk on 03.11.23.
//

import SwiftUI
import KeychainAccess
import Combine

/// https://www.avanderlee.com/swift/appstorage-explained/
final class Preferences {
    static let standard = Preferences(userDefaults: .standard, keychain: Keychain())
    let userDefaults: UserDefaults
    let keychain: Keychain

    /// Sends through the changed key path whenever a change occurs.
    var preferencesChangedSubject = PassthroughSubject<AnyKeyPath, Never>()

    init(userDefaults: UserDefaults, keychain: Keychain) {
        self.userDefaults = userDefaults
        self.keychain = keychain
    }

    @KeychainEntry(Constants.PreferencesKey.bearAPIToken.rawValue)
    var bearAPIToken: String = ""

    @KeychainEntry(Constants.PreferencesKey.gitRepoURL.rawValue)
    var gitRepoURL: String = ""

    @UserDefault(Constants.PreferencesKey.instanceId.rawValue)
    var instanceId: String = ""

    @UserDefault(Constants.PreferencesKey.tags.rawValue)
    var tags: [String] = []

    @UserDefault(Constants.PreferencesKey.useSQLite.rawValue)
    var useSQLite: Bool = false
}
