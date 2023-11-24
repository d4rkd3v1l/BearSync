//
//  Preferences.swift
//  BearAppSync
//
//  Created by d4Rk on 03.11.23.
//

import SwiftUI
import KeychainAccess
import Combine

// MARK: - Preferences

/// https://www.avanderlee.com/swift/appstorage-explained/
final class Preferences {
    static let standard = Preferences(userDefaults: .standard, keychain: Keychain())
    fileprivate let userDefaults: UserDefaults
    fileprivate let keychain: Keychain

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

    // TODO: InstanceId
}

// MARK: - Preference

@propertyWrapper
struct Preference<Value>: DynamicProperty {
    @ObservedObject private var preferencesObserver: PublisherObservableObject
    private let keyPath: ReferenceWritableKeyPath<Preferences, Value>
    private let preferences: Preferences

    init(_ keyPath: ReferenceWritableKeyPath<Preferences, Value>, preferences: Preferences = .standard) {
        self.keyPath = keyPath
        self.preferences = preferences
        let publisher = preferences
            .preferencesChangedSubject
            .filter { changedKeyPath in
                changedKeyPath == keyPath
            }.map { _ in () }
            .eraseToAnyPublisher()
        self.preferencesObserver = .init(publisher: publisher)
    }

    var wrappedValue: Value {
        get { preferences[keyPath: keyPath] }
        nonmutating set { preferences[keyPath: keyPath] = newValue }
    }

    var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

// MARK: - UserDefault

@propertyWrapper
struct UserDefault<Value> {
    let key: String
    let defaultValue: Value

    var wrappedValue: Value {
        get { fatalError("Wrapped value should not be used.") }
        set { fatalError("Wrapped value should not be used.") }
    }

    init(wrappedValue: Value, _ key: String) {
        self.defaultValue = wrappedValue
        self.key = key
    }

    public static subscript(
        _enclosingInstance instance: Preferences,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Preferences, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Preferences, Self>
    ) -> Value {
        get {
            let container = instance.userDefaults
            let key = instance[keyPath: storageKeyPath].key
            let defaultValue = instance[keyPath: storageKeyPath].defaultValue
            return container.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            let container = instance.userDefaults
            let key = instance[keyPath: storageKeyPath].key
            container.set(newValue, forKey: key)
            instance.preferencesChangedSubject.send(wrappedKeyPath)
        }
    }
}

// MARK: - KeychainEntry

@propertyWrapper
struct KeychainEntry<Value: Codable> {
    let key: String
    let defaultValue: Value

    var wrappedValue: Value {
        get { fatalError("Wrapped value should not be used.") }
        set { fatalError("Wrapped value should not be used.") }
    }

    init(wrappedValue: Value, _ key: String) {
        self.defaultValue = wrappedValue
        self.key = key
    }

    public static subscript(
        _enclosingInstance instance: Preferences,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Preferences, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Preferences, Self>
    ) -> Value {
        get {
            let container = instance.keychain
            let key = instance[keyPath: storageKeyPath].key
            let defaultValue = instance[keyPath: storageKeyPath].defaultValue

            do {
                return try container.get(key) { attributes in
                    if let attributes = attributes,
                       let data = attributes.data {

                        do {
                            let decoded = try JSONDecoder().decode(Value?.self, from: data)
                            return decoded ?? defaultValue
                        } catch let error {
                            print("[KeychainStorage] Keychain().get(\(key)) - \(error.localizedDescription)")
                            return defaultValue
                        }
                    }
                    return defaultValue
                }
            } catch let error {
                print("\(error)")
                return defaultValue
            }
        }
        set {
            let container = instance.keychain
            let key = instance[keyPath: storageKeyPath].key

            do {
                let encoded = try JSONEncoder().encode(newValue)
                try container.set(encoded, key: key)
            } catch {
                fatalError("\(error)")
            }

            instance.preferencesChangedSubject.send(wrappedKeyPath)
        }
    }
}
