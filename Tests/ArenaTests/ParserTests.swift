//
//  ParserTests.swift
//  ArenaTests
//
//  Created by Sven A. Schmidt on 27/03/2020.
//

@testable import ArenaCore
import Path
import Parser
import Workspace
import XCTest


class ParserTests: XCTestCase {

    func test_parse_version() throws {
        XCTAssertEqual(Parser.version.run("1.2.3"), Match(result: Version(1, 2, 3), rest: ""))
        XCTAssertEqual(Parser.version.run("1.2.3="), Match(result: Version(1, 2, 3), rest: "="))
    }

    func test_parse_requirement() throws {
        XCTAssertEqual(Parser.exact.run("@1.2.3"), Match(result: .exact("1.2.3"), rest: ""))

        XCTAssertEqual(Parser.from.run("@from:1.2.3"), Match(result: .from("1.2.3"), rest: ""))

        XCTAssertEqual(Parser.range.run("@1.2.3..<3.2.1"), Match(result: .range("1.2.3"..<"3.2.1"), rest: ""))
        XCTAssertEqual(Parser.range.run("@1.2.3...3.2.1"), Match(result: .range("1.2.3"..<"3.2.2"), rest: ""))

        do {  // combined
            XCTAssertEqual(Parser.refSpec.run(""), Match(result: .noVersion, rest: ""))
            XCTAssertEqual(Parser.refSpec.run("@1.2.3"), Match(result: .exact("1.2.3"), rest: ""))
            XCTAssertEqual(Parser.refSpec.run("@from:1.2.3"), Match(result: .from("1.2.3"), rest: ""))
            XCTAssertEqual(Parser.refSpec.run("@1.2.3..<3.0.0"), Match(result: .range("1.2.3"..<"3.0.0"), rest: ""))
        }
    }

    func test_parse_url() throws {
        XCTAssertEqual(Parser.url.run("https://github.com/foo/bar"),
                       Match(result: URL(string: "https://github.com/foo/bar"), rest: ""))
        XCTAssertEqual(Parser.url.run("https://github.com/foo/bar@rest"),
                       Match(result: URL(string: "https://github.com/foo/bar"), rest: "@rest"))
        XCTAssertEqual(Parser.url.run("http://github.com/foo/bar@rest"),
                       Match(result: URL(string: "http://github.com/foo/bar"), rest: "@rest"))
        XCTAssertEqual(Parser.url.run("/foo/bar@rest"),
                       Match(result: URL(string: "file:///foo/bar"), rest: "@rest"))
        XCTAssertEqual(Parser.url.run("file:///foo/bar@rest"),
                       Match(result: URL(string: "file:///foo/bar"), rest: "@rest"))
        XCTAssertEqual(Parser.url.run("file:/foo/bar@rest"),
                       Match(result: URL(string: "file:///foo/bar"), rest: "@rest"))
    }

    func test_parse_branchName() {
        XCTAssertEqual(branchName.run("develop"), Match(result: "develop", rest: ""))
        XCTAssertEqual(branchName.run("foo-bar"), Match(result: "foo-bar", rest: ""))
        // disallowed
        XCTAssertEqual(branchName.run("/foo"), Match(result: nil, rest: "/foo"))
        XCTAssertEqual(branchName.run("foo."), Match(result: nil, rest: "foo."))
        XCTAssertEqual(branchName.run("foo/"), Match(result: nil, rest: "foo/"))
    }

    func test_parse_branch() {
        XCTAssertEqual(Parser.branch.run("@branch:develop"), Match(result: .branch("develop"), rest: ""))
    }

    func test_parse_revision() {
        XCTAssertEqual(Parser.revision.run("@revision:foo"), Match(result: .revision("foo"), rest: ""))
        XCTAssertEqual(Parser.revision.run("@revision:7ba3c50793d971b50bc748ad4c9a061ba8e6a0c5"), Match(result: .revision("7ba3c50793d971b50bc748ad4c9a061ba8e6a0c5"), rest: ""))
        XCTAssertEqual(Parser.revision.run("@revision:1.2.3-rc4"), Match(result: .revision("1.2.3-rc4"), rest: ""))
    }

    func test_parse_dependency() throws {
        XCTAssertEqual(Parser.dependency.run("https://github.com/foo/bar"),
                       Match(result: Dependency(url: URL(string: "https://github.com/foo/bar")!,
                                                requirement: .noVersion),
                             rest: ""))
        XCTAssertEqual(Parser.dependency.run("https://github.com/foo/bar@1.2.3"),
                       Match(result: Dependency(url: URL(string: "https://github.com/foo/bar")!,
                                                requirement: .exact("1.2.3")),
                             rest: ""))
        XCTAssertEqual(Parser.dependency.run("https://github.com/foo/bar@from:1.2.3"),
                       Match(result: Dependency(url: URL(string: "https://github.com/foo/bar")!,
                                                requirement: .from("1.2.3")),
                             rest: ""))
        XCTAssertEqual(Parser.dependency.run("https://github.com/foo/bar@1.2.3..<4.0.0"),
                       Match(result: Dependency(url: URL(string: "https://github.com/foo/bar")!,
                                                requirement: .range("1.2.3"..<"4.0.0")),
                             rest: ""))
        XCTAssertEqual(Parser.dependency.run("https://github.com/foo/bar@1.2.3...4.0.0"),
                       Match(result: Dependency(url: URL(string: "https://github.com/foo/bar")!,
                                                requirement: .range("1.2.3"..<"4.0.1")),
                             rest: ""))
        XCTAssertEqual(Parser.dependency.run("https://github.com/foo/bar@branch:develop"),
                       Match(result: Dependency(url: URL(string: "https://github.com/foo/bar")!,
                                                requirement: .branch("develop")),
                             rest: ""))
        XCTAssertEqual(Parser.dependency.run("https://github.com/foo/bar@branch:feature/a"),
                       Match(result: Dependency(url: URL(string: "https://github.com/foo/bar")!,
                                                requirement: .branch("feature/a")),
                             rest: ""))
        XCTAssertEqual(Parser.dependency.run("https://github.com/foo/bar@revision:somerevision"),
                       Match(result: Dependency(url: URL(string: "https://github.com/foo/bar")!,
                                                requirement: .revision("somerevision")),
                             rest: ""))

        // local path dependency
        XCTAssertEqual(
            Parser.dependency.run("/foo/bar"),
            Match(result: Dependency(url: URL(string: "file:///foo/bar")!, requirement: .path), rest: ""))
        XCTAssertEqual(
            Parser.dependency.run("./foo/bar"),
            Match(result: Dependency(url: URL(string: "file://\(Path.cwd)/foo/bar")!, requirement: .path), rest: ""))
        XCTAssertEqual(
            Parser.dependency.run("~/foo/bar"),
            Match(result: Dependency(url: URL(string: "file://\(Path.home)/foo/bar")!, requirement: .path), rest: ""))
        XCTAssertEqual(
            Parser.dependency.run("foo/bar"),
            Match(result: Dependency(url: URL(string: "file://\(Path.cwd)/foo/bar")!, requirement: .path), rest: ""))
        XCTAssertEqual(
            Parser.dependency.run("../foo/bar"),
            Match(result: Dependency(url: URL(string: "file://\(Path.cwd/"../foo/bar")")!, requirement: .path), rest: ""))
    }

    func test_parse_dependency_git_protocol() throws {
        // git protocol
        XCTAssertEqual(Parser.dependency.run("git@github.com:foo/bar.git"),
                       Match(result: Dependency(url: URL(string: "ssh://git@github.com/foo/bar.git")!,
                                                requirement: .noVersion),
                             rest: ""))
        XCTAssertEqual(Parser.dependency.run("git@github.com:foo/bar"),
                       Match(result: Dependency(url: URL(string: "ssh://git@github.com/foo/bar")!,
                                                requirement: .noVersion),
                             rest: ""))
    }

    func test_parse_dependency_errors() throws {
        // unparsable trailing characters
        XCTAssertEqual(Parser.dependency.run("https://github.com/foo/bar@from:1.2.3trailingjunk"),
                       Match(result: nil,
                             rest: "https://github.com/foo/bar@from:1.2.3trailingjunk"))
        // invalid version
        XCTAssertEqual(Parser.dependency.run("https://github.com/foo/bar@from:1.2.3..<2.0.0"),
                       Match(result: nil,
                             rest: "https://github.com/foo/bar@from:1.2.3..<2.0.0"))
        // invalid branch
        XCTAssertEqual(Parser.dependency.run("https://github.com/foo/bar@branch:foo bar"),
                       Match(result: nil,
                             rest: "https://github.com/foo/bar@branch:foo bar"))
        // invalid revision
        XCTAssertEqual(Parser.dependency.run("https://github.com/foo/bar@revision:1.2.3 rc4"),
                       Match(result: nil,
                             rest: "https://github.com/foo/bar@revision:1.2.3 rc4"))
    }

}
