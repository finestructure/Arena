@testable import ArenaCore
import Path
import Parser
import Workspace
import XCTest


extension ArenaCore.FileManager {
    static let mock = Self(
        fileExists: { _ in true }
    )
}


extension GithubClient {
    static let mock = Self(
        latestRelease: { _ in Release(tagName: "1.2.3") }
    )
}


extension Environment {
    static let mock = Self(
        fileManager: .mock, githubClient: .mock
    )
}


final class ArenaTests: XCTestCase {
    override func setUp() {
        Current = .mock
    }

    func test_loadManifest() throws {
        let p = checkoutsDirectory/"swift-package-manager"
        print(p)
        let package = AbsolutePath(p.string)
        let manifest = try ManifestLoader.loadManifest(packagePath: package,
                                                       swiftCompiler: swiftCompiler,
                                                       packageKind: .remote)
        XCTAssertEqual(manifest.name, "SwiftPM")
        XCTAssertEqual(manifest.products.map { $0.name }, ["SwiftPM", "SwiftPM-auto", "PackageDescription"])
        XCTAssertEqual(manifest.products.map { $0.type }, [.library(.dynamic), .library(.automatic), .library(.dynamic)])
    }

    func test_getPackageInfo() throws {
        let package = checkoutsDirectory/"swift-package-manager"
        XCTAssertEqual(try getPackageInfo(for: package).libraries,
                       ["SwiftPM", "SwiftPM-auto", "PackageDescription"])
    }

    func test_args_multiple_deps() throws {
        let args = ["https://github.com/mxcl/Path.swift.git@1.2.3", "https://github.com/hartbit/Yaap.git@from:1.0.0"]
        let res = try Arena.parse(args)
        XCTAssertEqual(res.dependencies, [
            Dependency(url: URL(string: "https://github.com/mxcl/Path.swift.git")!, requirement: .exact("1.2.3")),
            Dependency(url: URL(string: "https://github.com/hartbit/Yaap.git")!, requirement: .from("1.0.0"))
        ])
    }

    func test_args_github_shorthand() throws {
        do { // path doesn't exist
            Current.fileManager.fileExists = { _ in false }
            Current.githubClient.latestRelease = { _ in Release(tagName: "1.2.3") }
            let args = ["finestructure/gala"]
            let res = try Arena.parse(args)
            XCTAssertEqual(res.dependencies, [
                Dependency(url: URL(string: "https://github.com/finestructure/gala")!, requirement: .from("1.2.3")),
            ])
        }
        do { // path exists
            // This test is a little weird, because we override the fileExists check
            // to suggest a path exists while the path it actually resolves to is a
            // different one. But the premise of the test is to ensure it doesn't
            // get the shorthand treatement.
            // In general, it would probably be safe (safer?) to require that paths
            // are either absolute or relative with a leading ./ or ../
            Current.fileManager.fileExists = { _ in true }
            let args = ["finestructure/gala"]
            let res = try Arena.parse(args)
            XCTAssertEqual(res.dependencies.count, 1)
            #if swift(>=5.2)
            let dep = try XCTUnwrap(res.dependencies.first)
            #else
            let dep = res.dependencies.first!
            #endif
            XCTAssertEqual(dep.requirement, .path)
            XCTAssert(dep.url.isFileURL)
            XCTAssert(dep.url.path.hasSuffix("/finestructure/gala"))
        }
        do { // with refspec
            Current.fileManager.fileExists = { _ in false }
            let args = ["finestructure/gala@from:0.1.0"]
            let res = try Arena.parse(args)
            XCTAssertEqual(res.dependencies, [
                Dependency(url: URL(string: "https://github.com/finestructure/gala")!, requirement: .from("0.1.0")),
            ])
        }
        do { // with branch
            Current.fileManager.fileExists = { _ in false }
            let args = ["finestructure/gala@branch:feature/foo"]
            let res = try Arena.parse(args)
            XCTAssertEqual(res.dependencies, [
                Dependency(url: URL(string: "https://github.com/finestructure/gala")!, requirement: .branch("feature/foo")),
            ])
        }
    }

    func test_args_order() throws {
        // ensure the --force flag (for instance) can be a trailing argument
        do {
            let args = ["-f", "https://github.com/mxcl/Path.swift.git@1.2.3", "https://github.com/hartbit/Yaap.git@from:1.0.0"]
            let res = try Arena.parse(args)
            XCTAssertEqual(res.dependencies, [
                Dependency(url: URL(string: "https://github.com/mxcl/Path.swift.git")!, requirement: .exact("1.2.3")),
                Dependency(url: URL(string: "https://github.com/hartbit/Yaap.git")!, requirement: .from("1.0.0"))
            ])
            XCTAssertTrue(res.force)
        } catch {
            XCTFail(error.localizedDescription)
        }
        do {
            let args = ["https://github.com/mxcl/Path.swift.git@1.2.3", "https://github.com/hartbit/Yaap.git@from:1.0.0", "-f"]
            let res = try Arena.parse(args)
            XCTAssertEqual(res.dependencies, [
                Dependency(url: URL(string: "https://github.com/mxcl/Path.swift.git")!, requirement: .exact("1.2.3")),
                Dependency(url: URL(string: "https://github.com/hartbit/Yaap.git")!, requirement: .from("1.0.0"))
            ])
            XCTAssertTrue(res.force)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }


    func test_args_multiple_libs() throws {
        let args = ["-l", "foo", "bar"]
        let res = try Arena.parse(args)
        XCTAssertEqual(res.libNames, ["foo", "bar"])
    }

    func test_dependency_package_clause() throws {
        do {
            let dep = Dependency(url: URL(string: "https://github.com/foo/bar")!, requirement: .branch("develop"))
            XCTAssertEqual(dep.packageClause(), #".package(url: "https://github.com/foo/bar", .branch("develop"))"#)
        }
        do {
            let dep = Dependency(url: URL(string: "https://github.com/foo/bar")!, requirement: .exact("1.2.3"))
            XCTAssertEqual(dep.packageClause(), #".package(url: "https://github.com/foo/bar", .exact("1.2.3"))"#)
        }
        do {
            let dep = Dependency(url: URL(string: "https://github.com/foo/bar")!, requirement: .from("1.2.3"))
            XCTAssertEqual(dep.packageClause(), #".package(url: "https://github.com/foo/bar", from: "1.2.3")"#)
        }
        do {
            let dep = Dependency(url: URL(string: "https://github.com/foo/bar")!, requirement: .range("1.2.3"..<"2.3.4"))
            XCTAssertEqual(dep.packageClause(), #".package(url: "https://github.com/foo/bar", "1.2.3"..<"2.3.4")"#)
        }
        do {
            let dep = Dependency(url: URL(string: "https://github.com/foo/bar")!, requirement: .revision("foo"))
            XCTAssertEqual(dep.packageClause(), #".package(url: "https://github.com/foo/bar", .revision("foo"))"#)
        }
        do {
            let dep = Dependency(url: URL(string: "file:///foo/bar")!, requirement: .path)
            XCTAssertEqual(dep.packageClause(), #".package(path: "/foo/bar")"#)
        }
        do {
            let dep = Dependency(url: URL(string: "https://github.com/foo/bar")!, requirement: .revision("foo"))
            XCTAssertEqual(dep.packageClause(name: "bar"), #".package(name: "bar", url: "https://github.com/foo/bar", .revision("foo"))"#)
        }
        do {
            let dep = Dependency(url: URL(string: "file:///foo/bar")!, requirement: .path)
            XCTAssertEqual(dep.packageClause(name: "bar"), #".package(name: "bar", path: "/foo/bar")"#)
        }
    }

    func test_latestRelease() throws {
        Current.githubClient.latestRelease = { _ in Release(tagName: "1.2.3") }
        do { // github url
            Current.fileManager.fileExists = { _ in false }
            let args = ["https://github.com/finestructure/gala"]
            let res = try Arena.parse(args)
            XCTAssertEqual(res.dependencies, [
                Dependency(url: URL(string: "https://github.com/finestructure/gala")!, requirement: .from("1.2.3")),
            ])
        }
        do { // github shorthand
            Current.fileManager.fileExists = { _ in false }
            let args = ["finestructure/gala"]
            let res = try Arena.parse(args)
            XCTAssertEqual(res.dependencies, [
                Dependency(url: URL(string: "https://github.com/finestructure/gala")!, requirement: .from("1.2.3")),
            ])
        }
        do { // other url
            Current.fileManager.fileExists = { _ in false }
            let args = ["https://gitlab.com/finestructure/foo"]
            let res = try Arena.parse(args)
            XCTAssertEqual(res.dependencies, [
                Dependency(url: URL(string: "https://gitlab.com/finestructure/foo")!, requirement: .from("0.0.0")),
            ])
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


