//
//  KeychainEntry.swift
//  BearAppSync
//
//  Created by d4Rk on 25.11.23.
//

import SwiftUI
import KeychainAccess

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
