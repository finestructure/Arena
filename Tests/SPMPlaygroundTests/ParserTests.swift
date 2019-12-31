//
//  ParserTests.swift
//  SPMPlaygroundTests
//
//  Created by Sven A. Schmidt on 30/12/2019.
//

import XCTest
@testable import SPMPlayground


class ParserTests: XCTestCase {

    func test_end() {
        do {
            let m = Parser<Void>.end.run("a")
            XCTAssertNil(m.result)
            XCTAssertEqual(m.rest, "a")
        }
        do {
            let m = Parser<Void>.end.run("")
            XCTAssertNotNil(m.result)
            XCTAssertEqual(m.rest, "")
        }
    }

    func test_prefix_while() throws {
        XCTAssertEqual(prefix(while: { $0 == "a" }).run("abc"), Match(result: "a", rest: "bc"))
        XCTAssertEqual(prefix(while: { CharacterSet.letters.contains(character: $0) }).run("abc123"), Match(result: "abc", rest: "123"))
    }

    func test_CharacterSet_contains_character() {
        XCTAssertTrue(CharacterSet.decimalDigits.contains(character: "3"))
        XCTAssertFalse(CharacterSet.decimalDigits.contains(character: "a"))
        XCTAssertTrue(CharacterSet(charactersIn: "👩‍👩‍👧‍👦").contains(character: "👩‍👩‍👧‍👦"))
        XCTAssertFalse(CharacterSet(charactersIn: "👩").contains(character: "👩‍👩‍👧‍👦"))
        XCTAssertFalse(CharacterSet(charactersIn: "👩‍👩‍👧‍👦").contains(character: "👩"))
    }

}

