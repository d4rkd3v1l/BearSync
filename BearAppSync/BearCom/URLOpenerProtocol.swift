//
//  URLOpenerProtocol.swift
//  BearAppSync
//
//  Created by d4Rk on 01.11.23.
//

import SwiftUI

protocol URLOpener {
    @discardableResult
    func open(_ url: URL) -> Bool
}

extension NSWorkspace: URLOpener {}
