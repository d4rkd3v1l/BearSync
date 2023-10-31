//
//  BearAppComTests.swift
//  BearAppSyncTests
//
//  Created by d4Rk on 27.10.23.
//

import XCTest
@testable import BearAppSync

final class BearComTests: XCTestCase {
    private var sut: BearCom!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let urlOpener = MockURLOpener()
        sut = BearCom(urlOpener: urlOpener)
        urlOpener.urlCallBackHandler = sut.handleURL
    }
    
    func testSearchSuccess() async throws {
        let searchResult = try? await sut.search(tag: "success")
        XCTAssertEqual(try XCTUnwrap(searchResult).notes.count, 5)
    }
    
    func testSearchFailure() async throws {
        let searchResult = try? await sut.search(tag: "failure")
        XCTAssertNil(searchResult)
    }
    
    func testOpenNoteSuccess() async throws {
        let openNoteResult = try? await sut.openNote(UUID(uuidString: "13371337-1337-1337-1337-133713371337")!)
        XCTAssertEqual(try XCTUnwrap(openNoteResult).identifier, UUID(uuidString: "2593B4B6-F3B8-45CA-A260-ABAB13E380E9")!)
    }
    func testOpenNoteFailure() async throws {
        let openNoteResult = try? await sut.openNote(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        XCTAssertNil(openNoteResult)
    }
    
    func testCreateSuccess() async throws {
        let createResult = try? await sut.create(with: "success")
        XCTAssertEqual(try XCTUnwrap(createResult).identifier, UUID(uuidString: "6E06ACC8-E68F-4F5F-A21C-6A1448B75F2D")!)
    }
    
    func testCreateFailure() async throws {
        let createResult = try? await sut.create(with: "failure")
        XCTAssertNil(createResult)
    }
    
    func testAddTextSuccess() async throws {
        let addTextResult = try? await sut.addText("success", to: UUID())
        XCTAssertEqual(try XCTUnwrap(addTextResult).title, "Test2")
    }
    
    func testAddTextFailure() async throws {
        let addTextResult = try? await sut.addText("failure", to: UUID())
        XCTAssertNil(addTextResult)
    }
    
    func testTrash() async throws {
        XCTFail("Not implemented")
    }
}

// MARK: - MockURLOpener

class MockURLOpener: URLOpener {
    var urlCallBackHandler: ((URL) -> Void)?
    
    func open(_ url: URL) -> Bool {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let successURLString = urlComponents.queryItems?["x-success"],
              let successURL = URL(string: successURLString),
              let successURLComponents = URLComponents(url: successURL, resolvingAgainstBaseURL: true),
              let requestId = successURLComponents.queryItems?["requestId"],
              let action = Action(rawValue: url.lastPathComponent) else { return false }
        
        let response: URL
        
        switch action {
        case .search:
            if let tag = urlComponents.queryItems?["tag"], tag == "success" {
                response = URL(string:  "bearappsync://x-callback-url/search?requestId=\(requestId)&notes=%5B%7B%22creationDate%22:%222023-10-30T07:48:48Z%22,%22tags%22:%22%5B%5C%22asdf-asdf_asf@asdf.asdf%3Dsdf!asdf%E2%80%9Dsdf%C2%A7asdf$asdf%25asdf%26asdf%3Fasdf%C3%A1sdf%60asdf%C2%B4asdf.asdf:asdf,asfd;ASdf%5Easdf%C2%B0asdf*sdfg+sdfg'sdfg%5C%5C%5C%5C%5C%5C%5C%5Csdfg%7Casdfg1%5C%22,%5C%22test%5C%5C%5C/nested%5C%22,%5C%22test%5C%22,%5C%22asdf%5C%22,%5C%22test%5C%5C%5C/deeply%5C%22,%5C%22test%5C%5C%5C/deeply%5C%5C%5C/nested%5C%22%5D%22,%22title%22:%22Test%202%20(nested%20tag)%22,%22modificationDate%22:%222023-10-30T07:48:48Z%22,%22identifier%22:%221FC5C65A-72AD-4137-BB92-A4B45DEF3C73%22,%22pin%22:%22no%22%7D,%7B%22creationDate%22:%222023-10-30T07:48:48Z%22,%22tags%22:%22%5B%5C%22test%5C%22%5D%22,%22title%22:%22Test%201%22,%22modificationDate%22:%222023-10-30T07:48:48Z%22,%22identifier%22:%22A2725271-E786-41AC-9F90-15485D25DA4C%22,%22pin%22:%22no%22%7D,%7B%22creationDate%22:%222023-10-30T07:48:48Z%22,%22tags%22:%22%5B%5C%22test%5C%22%5D%22,%22title%22:%22new%20file%22,%22modificationDate%22:%222023-10-30T07:48:48Z%22,%22identifier%22:%220A5544AB-EBB0-44C1-8B3B-2B753A7933AC%22,%22pin%22:%22no%22%7D,%7B%22creationDate%22:%222023-10-30T07:48:48Z%22,%22tags%22:%22%5B%5C%22test%5C%5C%5C/nested%5C%22,%5C%22test%5C%22%5D%22,%22title%22:%22Asdf%22,%22modificationDate%22:%222023-10-30T07:48:48Z%22,%22identifier%22:%2259C656DF-6376-4315-8AD0-71690BCD4CAA%22,%22pin%22:%22no%22%7D,%7B%22creationDate%22:%222023-10-30T07:48:07Z%22,%22tags%22:%22%5B%5C%22test%5C%22%5D%22,%22title%22:%22Test%20NEW%22,%22modificationDate%22:%222023-10-30T07:48:07Z%22,%22identifier%22:%22CB7D6167-EE5D-46A4-A2FA-BF1106D6D587%22,%22pin%22:%22no%22%7D%5D&")!
            } else {
                response = URL(string: "bearappsync://x-callback-url/search?requestId=\(requestId)&error-Code=2&errorMessage=The%20tag%20could%20not%20be%20found&errorDomain=The%20tag%20could%20not%20be%20found&")!
            }
            
        case .openNote:
            if let id = urlComponents.queryItems?["id"], id == "13371337-1337-1337-1337-133713371337" {
                response = URL(string:  "bearappsync://x-callback-url/open-note?requestId=\(requestId)&note=%23%20Asdf%0A%0A123%0AAsdf%0APdf%0A%0A---%0A%23test/nested%0A&modificationDate=2023-10-28T11:06:45Z&creationDate=2023-10-22T18:24:51Z&title=Asdf&is_trashed=no&identifier=2593B4B6-F3B8-45CA-A260-ABAB13E380E9&tags=%5B%22test%22,%22test%5C/nested%22%5D&")!
            } else {
                response = URL(string: "bearappsync://x-callback-url/open-note?requestId=\(requestId)&error-Code=2&errorMessage=The%20note%20could%20not%20be%20found&errorDomain=The%20note%20could%20not%20be%20found&")!
            }
            
        case .create:
            if let text = urlComponents.queryItems?["text"], text == "success" {
                response = URL(string: "bearappsync://x-callback-url/create?requestId=\(requestId)&title=Asdf&identifier=6E06ACC8-E68F-4F5F-A21C-6A1448B75F2D&")!
            } else {
                response = URL(string: "bearappsync://x-callback-url/create?requestId=\(requestId)&error-Code=1&errorMessage=The%20resulting%20note%20is%20empty&errorDomain=The%20resulting%20note%20is%20empty&")!
            }
            
        case .addText:
            if let text = urlComponents.queryItems?["text"], text == "success" {
                response = URL(string: "bearappsync://x-callback-url/add-text?requestId=\(requestId)&title=Test2&note=%23%20Test2%0A%0A13451rq%0A%0A---%0A%23test2%0A&")!
            } else {
                response = URL(string: "bearappsync://x-callback-url/add-text?requestId=\(requestId)&error-Code=1&errorMessage=Text%20provided%20empty&errorDomain=Text%20provided%20empty&")!
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.urlCallBackHandler?(response)
        }
        return true
    }
}
