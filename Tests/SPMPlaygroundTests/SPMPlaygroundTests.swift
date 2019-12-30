@testable import SPMPlayground
import Path
import Workspace
import XCTest


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

    func test_parse_multiple_deps() throws {
        do {
            var args = ["-d", "https://github.com/mxcl/Path.swift.git==1.2.3", "https://github.com/hartbit/Yaap.git>=1.0.0"]
            let cmd = SPMPlaygroundCommand()
            let res = try cmd.parse(arguments: &args)
            XCTAssert(res)
            XCTAssertEqual(cmd.dependencies, [
                Dependency(url: URL(string: "https://github.com/mxcl/Path.swift.git")!, requirement: .exact("1.2.3")),
                Dependency(url: URL(string: "https://github.com/hartbit/Yaap.git")!, requirement: .range("1.0.0"..<"2.0.0"))
            ])
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
            let res = Parser.exact.run("@1.2.3")
            XCTAssertEqual(res.match, .exact("1.2.3"))
            XCTAssertEqual(res.rest, "")
        }
        do {
            let res = Parser.upToNextMajor.run(">=1.2.3")
            XCTAssertEqual(res.match, .range("1.2.3"..<"2.0.0"))
            XCTAssertEqual(res.rest, "")
        }
        do {
            let res = Parser.upToNextMajor.run("@from:1.2.3")
            XCTAssertEqual(res.match, .range("1.2.3"..<"2.0.0"))
            XCTAssertEqual(res.rest, "")
        }
        do {
            let res = Parser.range.run(">=1.2.3<3.2.1")
            XCTAssertEqual(res.match, .range("1.2.3"..<"3.2.1"))
            XCTAssertEqual(res.rest, "")
        }
        do {
            let res = Parser.range.run("@1.2.3..<3.2.1")
            XCTAssertEqual(res.match, .range("1.2.3"..<"3.2.1"))
            XCTAssertEqual(res.rest, "")
        }
        do {
            let res = Parser.range.run("@1.2.3...3.2.1")
            XCTAssertEqual(res.match, .range("1.2.3"..<"3.2.2"))
            XCTAssertEqual(res.rest, "")
        }
        do {  // test partial matching
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

    func test_dependency_package_clause() throws {
        do {
            let dep = Dependency(url: URL(string: "https://github.com/foo/bar")!, requirement: .branch("develop"))
            XCTAssertEqual(dep.packageClause, #".package(url: "https://github.com/foo/bar", .branch("develop"))"#)
        }
        do {
            let dep = Dependency(url: URL(string: "https://github.com/foo/bar")!, requirement: .exact("1.2.3"))
            XCTAssertEqual(dep.packageClause, #".package(url: "https://github.com/foo/bar", .exact("1.2.3"))"#)
        }
        do {
            let dep = Dependency(url: URL(string: "https://github.com/foo/bar")!, requirement: .range("1.2.3"..<"2.3.4"))
            XCTAssertEqual(dep.packageClause, #".package(url: "https://github.com/foo/bar", "1.2.3"..<"2.3.4")"#)
        }
        do {
            let dep = Dependency(url: URL(string: "https://github.com/foo/bar")!, requirement: .revision("foo"))
            XCTAssertEqual(dep.packageClause, #".package(url: "https://github.com/foo/bar", .revision("foo"))"#)
        }
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


