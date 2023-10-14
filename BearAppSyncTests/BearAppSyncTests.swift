//
//  BearAppSyncTests.swift
//  BearAppSyncTests
//
//  Created by d4Rk on 04.10.23.
//

import XCTest
@testable import BearAppSync

final class BearAppSyncTests: XCTestCase {
    func testTags() throws {
        // TODO: Make `###tags` non match! And dont match `#sadf` of `#asdf#sadf` either, but match `asdf` ;-)
        let note = Note(uuid: "12345678-1234-1234-1234-123456789012", title: "1337", text: "#tag1 this is just a #test with different #tags or invalid like containing invalid chars #asdf(1234 and so on #)asdf #{sdgf #}asdgf #nested/tag #deeply/nested/tag")
        
        print(note.tags)
        
        XCTAssertEqual(note.tags.count, 9)
        XCTAssertTrue(note.tags.contains("tag1"))
        XCTAssertTrue(note.tags.contains("test"))
        XCTAssertTrue(note.tags.contains("tags"))
        XCTAssertTrue(note.tags.contains("asdf"))
        XCTAssertTrue(note.tags.contains("nested"))
        XCTAssertTrue(note.tags.contains("nested/tag"))
        XCTAssertTrue(note.tags.contains("deeply"))
        XCTAssertTrue(note.tags.contains("deeply/nested"))
        XCTAssertTrue(note.tags.contains("deeply/nested/tag"))
        XCTAssertTrue(note.tags.contains("tag1"))
    }
}
