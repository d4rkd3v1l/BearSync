//
//  SQLiteComError.swift
//  BearSync
//
//  Created by d4Rk on 25.01.24.
//

import Foundation

enum SQLiteComError: Error {
    case unknown
    case couldNotOpenDatabase
    case couldNotExecuteQuery
    case couldNotBindParameter
    case noteNotFound
    case couldNotParseNote
}
