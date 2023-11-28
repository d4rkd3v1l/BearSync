//
//  MappingTests.swift
//  BearSyncTests
//
//  Created by d4Rk on 30.10.23.
//

import XCTest
@testable import BearSync

final class MappingTests: XCTestCase {

    private var sut: Mapping!
    
    let file1Id = UUID(uuidString: "00000000-F17E-0000-0000-000000000001")!
    let file2Id = UUID(uuidString: "00000000-F17E-0000-0000-000000000002")!
    let file3Id = UUID(uuidString: "00000000-F17E-0000-0000-000000000003")!
    let file4Id = UUID(uuidString: "00000000-F17E-0000-0000-000000000004")!
    let instance1Id = UUID(uuidString: "00000000-1257-0000-0000-000000000001")!
    let instance2Id = UUID(uuidString: "00000000-1257-0000-0000-000000000002")!
    let note1Id = UUID(uuidString: "00000000-2073-0000-0000-000000000001")!
    let note2Id = UUID(uuidString: "00000000-2073-0000-0000-000000000002")!
    let note3Id = UUID(uuidString: "00000000-2073-0000-0000-000000000003")!
    let note4Id = UUID(uuidString: "00000000-2073-0000-0000-000000000004")!
    let note5Id = UUID(uuidString: "00000000-2073-0000-0000-000000000005")!
    
    override func setUpWithError() throws {
        let notes = [Mapping.Note(fileId: file1Id, references: [instance1Id: note1Id,
                                                                instance2Id: note2Id]),
                     Mapping.Note(fileId: file2Id, references: [instance1Id : note3Id]),
                     Mapping.Note(fileId: file3Id, references: [instance2Id : note4Id])]
        
        sut = Mapping(notes: notes)
    }
    
    func testNoteId() throws {
        let result = sut.noteId(for: file1Id, in: instance2Id)
        XCTAssertEqual(try XCTUnwrap(result), note2Id)
    }
    
    func testNoteIdNotFound() throws {
        let result = sut.noteId(for: file2Id, in: instance2Id)
        XCTAssertNil(result)
    }
    
    func testfileId() throws {
        let result = sut.fileId(for: note4Id, in: instance2Id)
        XCTAssertEqual(try XCTUnwrap(result), file3Id)
    }
    
    func testfileIdNotFound() throws {
        let result = sut.fileId(for: note3Id, in: instance2Id)
        XCTAssertNil(result)
    }
    
    func testAddNote() throws {
        XCTAssertEqual(sut.notes.count, 3)
        _ = sut.addNote(with: note3Id, for: instance2Id)
        XCTAssertEqual(sut.notes.count, 4)
    }
    
    func testRemoveNote() throws {
        let note = Mapping.Note(fileId: file3Id, references: [instance2Id : note4Id])
        sut.removeNote(note)
        XCTAssertEqual(sut.notes.count, 2)
    }

    func testAddReference() throws {
        let result = sut.addReference(to: file3Id, noteId: note5Id, instanceId: instance1Id)
        XCTAssertTrue(result)
    }
    
    func testAddReferenceError() throws {
        let result = sut.addReference(to: file4Id, noteId: note5Id, instanceId: instance1Id)
        XCTAssertFalse(result)
    }
    
    func testPersistence() throws {
        let tempDirPath = NSTemporaryDirectory()
        let tempDirURL = URL(fileURLWithPath: tempDirPath)
        let tempFileURL = tempDirURL.appendingPathComponent("mapping.json")
        try sut.save(to: tempFileURL)
        
        let loadedMapping = try Mapping.load(from: tempFileURL)
        
        XCTAssertEqual(loadedMapping, sut)
        
        try FileManager.default.removeItem(at: tempFileURL)
        try FileManager.default.removeItem(at: tempDirURL)
    }
}
