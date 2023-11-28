//
//  TriggerButtonStyle.swift
//  BearSync
//
//  Created by d4Rk on 25.11.23.
//

import SwiftUI

/// Stolen from https://github.com/orchetect/SettingsAccess
struct TriggerButtonStyle: PrimitiveButtonStyle {
    @Binding public var trigger: (() -> Void)?

    public func makeBody(configuration: Configuration) -> some View {
        DispatchQueue.main.async {
            trigger = {
                configuration.trigger()
            }
        }

        return Button(role: configuration.role) {
            configuration.trigger()
        } label: {
            configuration.label
        }
    }
}

/// Stolen from https://github.com/orchetect/SettingsAccess
class TriggerButtonAction: ObservableObject {
    // Closure to run when `openSettings()` is called.
    // Default to legacy Settings/Preferences window call.
    // This closure will be replaced with the new SettingsLink trigger later.
    private var closure: (() throws -> Void)?

    private(set) var binding: Binding<(() -> Void)?> = .constant(nil)

    // Set up a binding that allows us to update the closure property with a new closure later.
    init() {
        // closure will be updated by way of binding later
        binding = Binding(
            // get is never actually used, but it's provided in case.
            get: { [weak self] in
                guard let closure = self?.closure else { return nil }
                return { try? closure() }
            },
            set: { [weak self] newValue in
                if let newValue {
                    self?.closure = { newValue() }
                } else {
                    self?.closure = nil
                }
            }
        )
    }

    func callAsFunction() throws {
        try closure?()
    }
}
