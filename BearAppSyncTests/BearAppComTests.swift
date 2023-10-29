//
//  BearAppComTests.swift
//  BearAppSyncTests
//
//  Created by d4Rk on 27.10.23.
//

import XCTest
@testable import BearAppSync

final class BearAppComTests: XCTestCase {
    func testSearch() async throws {
        let searchResult = try? await BearCom.shared.search(tag: "test")
        XCTAssertEqual(try XCTUnwrap(searchResult).notes.count, 4)
    }
    
    func testOpenNote() async throws {
        let openNoteResult = try? await BearCom.shared.openNote("54DE61A0-FEAB-4D72-AB62-B45A5F7796E3")
        XCTAssertEqual(try XCTUnwrap(openNoteResult).identifier, "54DE61A0-FEAB-4D72-AB62-B45A5F7796E3")
    }
}
