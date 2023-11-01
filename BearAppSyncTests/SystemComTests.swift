//
//  SystemComTests.swift
//  BearAppSyncTests
//
//  Created by d4Rk on 30.10.23.
//

import XCTest
@testable import BearAppSync

final class SystemComTests: XCTestCase {
    private var systemCom: SystemCom!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
        systemCom = SystemCom(currentDirectory: url)
    }
    
    func testSimpleCommand() throws {
        systemCom.bash(standardOutput: { output in
            XCTAssertEqual(output, "/Users/1337-h4x0r/Library/Containers/com.d4Rk.BearAppSync2/Data/tmp\n")
        }, standardError: { _ in
            XCTFail("No error expected.")
        }, "pwd")
    }
    
    func testInvalidCommand() throws {
        systemCom.bash(standardOutput: { output in
            XCTFail("No standard output expected.")
        }, standardError: { error in
            XCTAssertEqual(error, "/bin/bash: invalid-command-that-does-not-exist: command not found\n")
        }, "invalid-command-that-does-not-exist")
    }
}
