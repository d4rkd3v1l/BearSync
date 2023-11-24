//
//  PreferencesTests.swift
//  BearAppSyncTests
//
//  Created by d4Rk on 23.11.23.
//

import XCTest
import KeychainAccess
@testable import BearAppSync

final class PreferencesTests: XCTestCase {
    var sut: Preferences {
        let userDefaults = UserDefaults(suiteName: "UnitTests")!
        let keychain = Keychain(service: "UnitTests")
        let preferences = Preferences(userDefaults: userDefaults, keychain: keychain)
        return preferences
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        let keychain = Keychain(service: "UnitTests")
        try keychain.removeAll()

        let userDefaults = UserDefaults(suiteName: "UnitTests")!
        userDefaults.removeObject(forKey: Constants.PreferencesKey.tags.rawValue)
    }

    func testKeychainEntry() throws {
        @Preference(\.bearAPIToken, preferences: sut) var bearAPIToken
        XCTAssertEqual(bearAPIToken, "")

        bearAPIToken = "1234567890"
        XCTAssertEqual(bearAPIToken, "1234567890")
    }

    func testUserDefault() throws {
        @Preference(\.tags, preferences: sut) var tags
        XCTAssertEqual(tags, [])

        tags = ["tag1", "tag2"]
        XCTAssertEqual(tags, ["tag1", "tag2"])
    }
}
