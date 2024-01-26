//
//  SQLiteComTests.swift
//  BearSyncTests
//
//  Created by d4Rk on 25.01.24.
//

import XCTest
@testable import BearSync

final class SQLiteComTests: XCTestCase {

    var sut: SQLiteCom!

    override func setUpWithError() throws {
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "test", ofType: "sqlite")

        sut = SQLiteCom(pathProvider: { path! })
    }

    func testSearchSuccess() async throws {
        let result = try await sut.search(tag: "bear/welcome")
        XCTAssertEqual(result.notes.count, 4)
    }

    func testSearchFailure() async throws {
        let result = try await sut.search(tag: "tag-that-does-not-exist")
        XCTAssertEqual(result.notes.count, 0)
    }

    func testOpenNoteSuccess() async throws {
        let result = try await sut.openNote("SFNote2Intro0")
        XCTAssertEqual(result.identifier, "SFNote2Intro0")
        XCTAssertEqual(result.title, "Get started with Bear")
        XCTAssertEqual(result.tags, "bear/welcome bear")
        XCTAssertEqual(result.modificationDate, "727953945.582078")
        XCTAssertEqual(result.creationDate, "727953945.579113")
        XCTAssertEqual(result.note, "# Get started with Bear \n\n![](Get%20Started%20-%20Illo%20Copy%202.png)\n\nThese Welcome Notes will help you get to know Bear. Feel free to reference these while working in your own notes. The other Welcome Notes in this series include:\n\n- [[Organize, search, and customize in Bear]] \n- [[Work faster and easier with Bear]]\n\n---\n## How to create a new note\nClick the **New Note button** (⌘+N) at the top of the Note List and start typing. The first line of every note is its title, the rest is up to you.\n\n----\n## Meet the Styles\nBear\'s custom keyboard is the control board styling your notes on iPhone and iPad. On macOS, the same functionalities are available in the style bar at the bottom of the editor. Both can be enabled via the **B*I*~U~ button**.\n![](Get%20Started%20-%20Keyboard%203.png)\n### 📝 Write with styles\nYou can add all kinds of text styles to your notes, including: **bold**, *italic*, ~underline~, ~~strikethrough~~, ==highlight==, headings,  [links](bear.app), lists, todos, tables, and more—and it all starts with the **Style Bar**.\n​\nUse the **B*I*~U~ button** (⇧+⌘+Y) at the top of Bear to reveal the Style Bar and many of the core tools available to you. You can combine styles together, like **bold** and ~underline~ on the same **~word~**. To apply all this formatting, Bear uses Markdown[^1], a simple way to add style to plain text by wrapping it with special characters. [Visit our support docs](https://bear.app/faq/) to learn more about using Markdown in Bear and how you can apply this formatting yourself.\n\n### 📷 More than text\nBear notes can hold just about any kind of file, from photos to PDFs to… we’ll spare you the full list. You can drag & drop any file in your notes or use the attachment function (it looks like a photo) on the Style Bar. You can trigger with **B*I*~U~ button** on iOS and iPadOS.\n\n### 🎨 Draw your ideas\nWhen it’s time to get visual, you can add sketches to your notes on iPad. To create a sketch anywhere in a note, tap the **B*I*~U~ button**, then the **Squiggly Line Sketch Button** (yes that is its technical name). An expandable canvas will appear with Apple’s PencilKit tools, just add your creativity.\n\n---\n\n## Know your note\nIs your note close to a word count for a work or school project? How long will it take to read? Press ⓘ to reveal the **Info Panel** with these and other live statistics about your note. \n\nUse the **Table of Contents** tab in the Info Panel to see a layout of your note, based on headings 1-6. Click the **Backlinks** tab to view a list of all notes that link to the current note.\n\n---\n\n## Ready to write your first note?\nYour training is complete. Well, at least enough to get started with your own notes. To learn about more features, including: a powerful way to organize your notes with **tags** and the **Sidebar**, how to **sync** everything across all your devices with [Bear Pro](https://bear.app/faq/), and some advanced tips, check out the rest of our Welcome Notes below:\n\n* [[Organize, search, and customize in Bear]]\n* [[Work faster and easier with Bear]]\n\n---\n#### Footnotes\n[^1]: To be specific, Bear uses [CommonMark](https://commonmark.org), a well-defined and highly compatible specification of Markdown.\n\n#bear/welcome")
    }

    func testOpenNoteFailure() async throws {
        do {
            let result = try await sut.openNote("InvalidIdentifier")
            XCTFail("Error expected.")
        } catch {
            XCTAssertEqual(error as! SQLiteComError, .noteNotFound)
        }
    }
}
