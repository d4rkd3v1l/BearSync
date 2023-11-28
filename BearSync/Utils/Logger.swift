//
//  Logger.swift
//  BearSync
//
//  Created by d4Rk on 22.11.23.
//

import Foundation

final class Logger {

    private let logFile: URL
    private let dateFormatter: DateFormatter

    init(logFile: URL) {
        self.logFile = logFile
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    }

    func log(_ message: String) throws {
        let logEntry = "\(dateFormatter.string(from: Date.now)) \(message)\n"
        let logData = logEntry.data(using: .utf8)!

        if let fileHandle = FileHandle(forWritingAtPath: logFile.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            try fileHandle.write(contentsOf: logData)
        } else {
            try logData.write(to: logFile, options: .atomic)
        }
    }
}

