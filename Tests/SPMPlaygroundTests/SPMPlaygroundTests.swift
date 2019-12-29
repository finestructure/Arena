import XCTest
import class Foundation.Bundle
import PackageLoading
import Workspace
import Path
@testable import SPMPlayground
import PackageModel
import PackageLoading
import SPMUtility




final class SPMPlaygroundTests: XCTestCase {
    func test_loadManifest() throws {
        let p = checkoutsDirectory/"swift-package-manager"
        print(p)
        let package = AbsolutePath(p.string)
        let manifest = try ManifestLoader.loadManifest(packagePath: package, swiftCompiler: swiftCompiler)
        XCTAssertEqual(manifest.name, "SwiftPM")
        XCTAssertEqual(manifest.products.map { $0.name }, ["SwiftPM", "SwiftPM-auto", "SPMUtility"])
        XCTAssertEqual(manifest.products.map { $0.type }, [.library(.dynamic), .library(.automatic), .library(.automatic)])
    }

    func test_libraryNames() throws {
        let package = checkoutsDirectory/"swift-package-manager"
        XCTAssertEqual(try libraryNames(for: package), ["SwiftPM", "SwiftPM-auto", "SPMUtility"])
    }

    func test_parse_multiple_urls() throws {
        do {
            var args = ["-u", "https://github.com/mxcl/Path.swift.git", "https://github.com/hartbit/Yaap.git"]
            let cmd = SPMPlaygroundCommand()
            let res = try cmd.parse(arguments: &args)
            XCTAssert(res)
            XCTAssertEqual(cmd.pkgURLs, ["https://github.com/mxcl/Path.swift.git", "https://github.com/hartbit/Yaap.git"])
            XCTAssertEqual(cmd.pkgFrom, [])
        }
        do {
            var args = [
                "-u", "https://github.com/mxcl/Path.swift.git", "https://github.com/hartbit/Yaap.git",
                "-f", "0.0.0", "1.0.0"
            ]
            let cmd = SPMPlaygroundCommand()
            let res = try cmd.parse(arguments: &args)
            XCTAssert(res)
            XCTAssertEqual(cmd.pkgURLs, ["https://github.com/mxcl/Path.swift.git", "https://github.com/hartbit/Yaap.git"])
            XCTAssertEqual(cmd.pkgFrom, ["0.0.0", "1.0.0"])
        }
    }

    func test_parse_version() throws {
        do {
            let res = Parser.version.run("1.2.3")
            XCTAssertEqual(res.match, Version(1, 2, 3))
            XCTAssertEqual(res.rest, "")
        }
        do {
            let res = Parser.version.run("1.2.3=")
            XCTAssertEqual(res.match, Version(1, 2, 3))
            XCTAssertEqual(res.rest, "=")
        }
    }

    func test_parse_requirement() throws {
        do {
            let res = Parser.exact.run("==1.2.3")
            XCTAssertEqual(res.match, .exact("1.2.3"))
            XCTAssertEqual(res.rest, "")
        }
        do {
            let res = Parser.upToNextMajor.run(">=1.2.3")
            XCTAssertEqual(res.match, .range("1.2.3"..<"2.0.0"))
            XCTAssertEqual(res.rest, "")
        }
        do {
            let res = Parser.range.run(">=1.2.3<3.2.1")
            XCTAssertEqual(res.match, .range("1.2.3"..<"3.2.1"))
            XCTAssertEqual(res.rest, "")
        }
        do {
            let res = Parser.upToNextMajor.run(">=1.2.3<4.0.0")
            XCTAssertEqual(res.match, .range("1.2.3"..<"2.0.0"))
            XCTAssertEqual(res.rest, "<4.0.0")
        }
        do {  // combined
            do {
                let res = Parser.requirement.run("")
                XCTAssertEqual(res.match, .range("0.0.0"..<"1.0.0"))
                XCTAssertEqual(res.rest, "")
            }
            do {
                let res = Parser.requirement.run("==1.2.3")
                XCTAssertEqual(res.match, .exact("1.2.3"))
                XCTAssertEqual(res.rest, "")
            }
            do {
                let res = Parser.requirement.run(">=1.2.3")
                XCTAssertEqual(res.match, .range("1.2.3"..<"2.0.0"))
                XCTAssertEqual(res.rest, "")
            }
            do {
                let res = Parser.requirement.run(">=1.2.3<3.0.0")
                XCTAssertEqual(res.match, .range("1.2.3"..<"3.0.0"))
                XCTAssertEqual(res.rest, "")
            }
        }
    }

    func test_parse_url() throws {
        do {
            let res = Parser.url.run("https://github.com/foo/bar")
            XCTAssertEqual(res.match, URL(string: "https://github.com/foo/bar"))
            XCTAssertEqual(res.rest, "")
        }
        do {
            let res = Parser.url.run("https://github.com/foo/bar==1.2.3")
            XCTAssertEqual(res.match, URL(string: "https://github.com/foo/bar"))
            XCTAssertEqual(res.rest, "==1.2.3")
        }
        do {
            let res = Parser.url.run("https://github.com/foo/bar>=1.2.3")
            XCTAssertEqual(res.match, URL(string: "https://github.com/foo/bar"))
            XCTAssertEqual(res.rest, ">=1.2.3")
        }
        do {
            let res = Parser.url.run("https://github.com/foo/bar>=1.2.3<3.0.0")
            XCTAssertEqual(res.match, URL(string: "https://github.com/foo/bar"))
            XCTAssertEqual(res.rest, ">=1.2.3<3.0.0")
        }
    }

    func test_parse_dependency() throws {
        do {
            let res = Parser.dependency.run("https://github.com/foo/bar")
            XCTAssertEqual(res.match?.url, URL(string: "https://github.com/foo/bar"))
            XCTAssertEqual(res.match?.requirement, .range("0.0.0"..<"1.0.0"))
            XCTAssertEqual(res.rest, "")
        }
    }

    func _test_parse_version_details() throws {
        // https://github.com/foo/bar==1.2.3        .exact("1.2.3")
        // https://github.com/foo/bar>=1.2.3        .upToNextMajor(from: "1.2.3")
        // https://github.com/foo/bar>=1.2.3<2.0.0  .range("1.2.3"..<"2.0.0"_
        do {
            let res = try parse(req: "https://github.com/foo/bar")
            XCTAssertEqual(res.url.absoluteString, "https://github.com/foo/bar")
            XCTAssertEqual(res.requirement, .range("0.0.0"..<"1.0.0"))
        }
        do {
            let res = try parse(req: "https://github.com/foo/bar==1.2.3")
            XCTAssertEqual(res.url.absoluteString, "https://github.com/foo/bar")
            XCTAssertEqual(res.requirement, .exact("1.2.3"))
        }
        do {
            let res = try parse(req: "https://github.com/foo/bar>=1.2.3")
            XCTAssertEqual(res.url.absoluteString, "https://github.com/foo/bar")
            XCTAssertEqual(res.requirement, .range("1.2.3"..<"2.0.0"))
        }
    }
}

enum ParseError: Error {
    case NoURL
    case InvalidURL
    case InvalidRequirement
    case InvalidVersion
}


typealias Requirement = PackageDependencyDescription.Requirement


struct Dependency {
    let url: Foundation.URL
    let requirement: Requirement
}


public let int = Parser<Int> { str in
  let prefix = str.prefix(while: { $0.isNumber })
  let match = Int(prefix)
  str.removeFirst(prefix.count)
  return match
}


extension Parser where A == Version {
    static var version: Parser<Version> {
        zip(int, literal("."), int, literal("."), int).map { major, _, minor, _, patch in
            Version(major, minor, patch)
        }
    }
}

extension Parser where A == Requirement {
    static var exact: Parser<Requirement> {
        zip(literal("=="), .version).map { _, version in
            Requirement.exact(version)
        }
    }

    static var upToNextMajor: Parser<Requirement> {
        zip(literal(">="), .version).map { _, version in
            Requirement.upToNextMajor(from: version)
        }
    }

    static var range: Parser<Requirement> {
        zip(literal(">="), .version, literal("<"), .version)
            .map { _, minVersion, _, maxVersion in
                Requirement.range(minVersion..<maxVersion)
        }
    }

    static var noVersion: Parser<Requirement> {
        return Parser { str in
            return str.isEmpty ? defaultReq : nil
        }
    }

    static var requirement: Parser<Requirement> {
        oneOf([.noVersion, .exact, .range, .upToNextMajor])
    }
}


extension Parser where A == Foundation.URL {
    static var url: Parser<Foundation.URL> {
        shortestOf([prefix(upTo: "=="), prefix(upTo: ">=")])
            .map(String.init)
            .flatMap {
                if let url = URL(string: $0) {
                    return always(url)
                } else {
                    return Parser<Foundation.URL>.never
                }
        }
    }
}


extension Parser where A == Dependency {
    static var dependency: Parser<Dependency> {
        zip(.url, .requirement).map { Dependency(url: $0.0, requirement: $0.1) }
    }
}


let defaultReq = Requirement.upToNextMajor(from: Version(0, 0, 0))


func parse(req: String) throws -> (url: Foundation.URL, requirement: Requirement) {
    let parts = req.components(separatedBy: "==")
    guard let urlString = parts.first else { throw ParseError.NoURL }
    guard let url = URL(string: urlString) else { throw ParseError.InvalidURL }
    let remainder = parts.dropFirst()
    guard remainder.count <= 1 else { throw ParseError.InvalidRequirement }

    if let s = remainder.first {
        guard let version = Version(string: s) else { throw ParseError.InvalidVersion }
        return (url, .exact(version))
    } else {
        return (url, .upToNextMajor(from: "0.0.0"))
    }
}


extension XCTestCase {
    /// Returns path to the built products directory.
    var productsDirectory: Foundation.URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }

    var projectDirectory: Foundation.URL {
        productsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    var checkoutsDirectory: Path {
        // if run via "swift test":
        // projectDirectory/.build/checkouts
        // if run via Xcode
        // projectDirectory(*)/SourcePackages/checkouts
        // where projectDirectory resolves to a path under DerivedData
        let path = Path(url: projectDirectory)!
        for testPath in ["/.build/checkouts", "/SourcePackages/checkouts"] {
            let p = path/testPath
            if p.exists {
                return p
            }
        }
        fatalError("checkouts directory not found!")
    }
}


