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

    // Verifies bugfix, where "tag detection" removed too much stuff, when links are in place
    func testMoreComplexNote() {
        let sut = """
# Headline
---
## Subheading
A list:
* Some 
* Entries inside
* the
* list, yo

---
## Another subheading level 2 or so ;-)
### and one with even level 3
* some more
* list
* entries

### Yet another headline^^
and a list, again:
* [link with spec1al & ch@r](https://some-url.com)
* [another special \\(@link\\)](https://another.url.bla)

### Challenges
* [Link](https://u.rl) 
* List
  * level 2 entry
  * Bla
  * Blub
  * …
* 1337

---
#some/nested #tag

[BearSync FileId]: <> (7EB77B9F-7242-40AB-9C12-C84AC8648156)

"""

        XCTAssertEqual(sut.tags, ["some/nested", "tag", "some"])
    }
}
