//
//  String+tagTests.swift
//  BearSyncTests
//
//  Created by d4Rk on 16.02.24.
//

import XCTest
@testable import BearSync

final class StringTagsTests: XCTestCase {
    func testTags() throws {
        let sut = """
asdfg #regularTag outside of any code blocks or links
sdfg
```bash
code
and not a #tag
#tag
```
#anotherTag
dfgojadgfe daf
asdfg
[some#link:asdf^/](as#df)
[sadf#asdf]

(#tagInBrackets)

```
more { code }
block
```

asdfg `code` asdf `code #more code`
"""
        XCTAssertEqual(sut.tags, ["regularTag", "anotherTag", "tagInBrackets"])
    }

    func testNestedTags() {
        let sut = """
This is some demo text.
Let's just put #some/nested/tags inside.
---

#another/nestedTag

"""

        XCTAssertEqual(sut.tags, ["some/nested/tags", "another/nestedTag", "some", "some/nested", "another"])
    }
}
