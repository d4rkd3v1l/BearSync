//
//  ExtensionTests.swift
//  BearAppSyncTests
//
//  Created by d4Rk on 30.10.23.
//

import XCTest
@testable import BearAppSync

final class ExtensionTests: XCTestCase {

    func testSha256() throws {
        let sut = "This is not a test, or is it?".sha256
        
        XCTAssertEqual(try XCTUnwrap(sut), "4314010838cf19d87e6de651758b477b5c43fc1b8440eb024f01e8dada507680")
    }
    
    func testArraySubscript() throws {
        let sut = [URLQueryItem(name: "name", value: "value"),
                   URLQueryItem(name: "anotherName", value: "anotherValue")]
        
        XCTAssertEqual(try XCTUnwrap(sut["anotherName"]), "anotherValue")
    }
}
