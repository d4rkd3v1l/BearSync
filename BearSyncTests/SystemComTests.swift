//
//  SystemComTests.swift
//  BearSyncTests
//
//  Created by d4Rk on 30.10.23.
//

import XCTest
@testable import BearSync

final class SystemComTests: XCTestCase {
    private var systemCom: SystemCom!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
        systemCom = SystemCom(currentDirectory: url)
    }
    
    func testSimpleCommand() throws {
        systemCom.bash(standardOutput: { output in
            XCTAssertEqual(output, "/Users\n")
        }, standardError: { _ in
            XCTFail("No error expected.")
        }, "cd /Users && pwd")
    }
    
    func testInvalidCommand() throws {
        systemCom.bash(standardOutput: { output in
            XCTFail("No standard output expected.")
        }, standardError: { error in
            XCTAssertEqual(error, "/bin/bash: invalid-command-that-does-not-exist: command not found\n")
        }, "invalid-command-that-does-not-exist")
    }
}
