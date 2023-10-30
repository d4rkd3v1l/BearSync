//
//  SystemCom.swift
//  BearAppSync
//
//  Created by d4Rk on 27.10.23.
//

import Foundation

class SystemCom {
    @discardableResult
    static func bash(currentDirectory: URL, 
                     standardOutput: ((String) -> Void)? = nil,
                     standardError: ((String) -> Void)? = nil,
                     _ args: String...) -> Int32 {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c"] + args
        task.currentDirectoryURL = currentDirectory
        
        let standardPipe = Pipe()
        task.standardOutput = standardPipe
        standardPipe.fileHandleForReading.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: .utf8) {
                // Update your view with the new text here
                if line != "" {
                    standardOutput?(line)
                }
            } else {
                print("Error decoding data: \(pipe.availableData)")
            }
        }
        
        let errorPipe = Pipe()
        task.standardError = errorPipe
        errorPipe.fileHandleForReading.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: .utf8) {
                // Update your view with the new text here
                if line != "" {
                    standardError?(line)
                }
            } else {
                print("Error decoding data: \(pipe.availableData)")
            }
        }

        
        try! task.run()
        task.waitUntilExit()
        return task.terminationStatus
    }
}
