//
//  WindowAccessor.swift
//  BearAppSync
//
//  Created by d4Rk on 25.11.23.
//

import SwiftUI

/// https://stackoverflow.com/a/77184303/2019384
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
