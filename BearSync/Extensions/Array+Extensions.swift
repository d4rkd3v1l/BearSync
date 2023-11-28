//
//  Array+Extensions.swift
//  BearSync
//
//  Created by d4Rk on 29.10.23.
//

import Foundation

extension Array where Element == URLQueryItem {
    subscript(name: String) -> String? {
        self.first(where: { $0.name == name })?.value
    }
}
