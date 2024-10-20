//
//  OpenNoteResultTests.swift
//  BearSyncTests
//
//  Created by d4Rk on 19.10.24.
//

import XCTest
@testable import BearSync

final class OpenNoteResultTests: XCTestCase {
    func testFileId() throws {
        let note = """
# Test Note

with some stuff inside

## more stuff
[Link](shouldnotmatch)

---
#some #tags #justbecause

[BearSync FileId]: <> (7EB77B9E-7242-40AB-9C12-C84AC8648155)

"""

        let sut = OpenNoteResult(note: note, identifier: "", title: "", tags: "", isTrashed: "", modificationDate: "", creationDate: "")


        XCTAssertEqual(try XCTUnwrap(sut.fileId), UUID(uuidString: "7EB77B9E-7242-40AB-9C12-C84AC8648155"))
    }

    func testNoFileId() throws {
        let note = """
# Test Note

with some stuff inside

## more stuff
[Link](shouldnotmatch)

---
#some #tags #justbecause
"""

        let sut = OpenNoteResult(note: note, identifier: "", title: "", tags: "", isTrashed: "", modificationDate: "", creationDate: "")


        XCTAssertNil(sut.fileId)
    }

    func testInvalidFileId() throws {
        let note = """
# Test Note

with some stuff inside

## more stuff
[Link](shouldnotmatch)

---
#some #tags #justbecause

[BearSync FileId]: <> (some-stuff-thats-not-a-uuid)

"""

        let sut = OpenNoteResult(note: note, identifier: "", title: "", tags: "", isTrashed: "", modificationDate: "", creationDate: "")


        XCTAssertNil(sut.fileId)
    }
}
