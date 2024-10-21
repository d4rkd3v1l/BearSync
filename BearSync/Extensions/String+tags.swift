//
//  String+tags.swift
//  BearSync
//
//  Created by d4Rk on 16.02.24.
//

import RegexBuilder

extension String {
    /// Simple tag detection
    ///
    /// Bear App is proprietary/closed source  and therefore the implementation of their tag detection is unknown.
    /// But this should get pretty close and at least cover a wide range of normal tag usage.
    var tags: [String] {
        let codeBlockRegex = Regex {
            "```"
            OneOrMore(CharacterClass.anyOf("```").inverted)
            "```"
        }

        let inlineCodeRegex = Regex {
            "`"
            OneOrMore(CharacterClass.anyOf("`").inverted)
            "`"
        }

        let linkRegex = Regex {
            "["
            OneOrMore(CharacterClass.anyOf("]").inverted)
            "]("
            OneOrMore(CharacterClass.anyOf(")").inverted)
            ")"
        }

        let simpleLinkRegex = Regex {
            "["
            OneOrMore(CharacterClass.anyOf("]").inverted)
            "]"
        }

        let strippedSelf = self
            .replacing(codeBlockRegex, with: "")
            .replacing(inlineCodeRegex, with: "")
            .replacing(linkRegex, with: "")
            .replacing(simpleLinkRegex, with: "")


        let tagRegex = Regex {
            "#"
            OneOrMore(CharacterClass(.anyOf("#(){}"), .whitespace).inverted)
        }

        let matches = strippedSelf.matches(of: tagRegex)
        var result = matches.map { match in
            String(strippedSelf[match.range.lowerBound..<match.range.upperBound].dropFirst())
        }

        // Nested tags
        result.enumerated().forEach {
            let nested = $0.element.split(separator: "/")
            for index in 0..<nested.count-1 {
                result.append(nested[0...index].joined(separator: "/"))
            }

        }

        return result
    }
}
