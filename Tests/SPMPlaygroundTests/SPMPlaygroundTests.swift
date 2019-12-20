import XCTest
import class Foundation.Bundle
import PackageLoading
import Workspace
import Path


final class SPMPlaygroundTests: XCTestCase {
    func testExample() throws {
        let p = checkoutsDirectory/"swift-package-manager"
        print(p)
        let package = AbsolutePath(p.string)
        let manifest = try ManifestLoader.loadManifest(packagePath: package, swiftCompiler: swiftCompiler)
        XCTAssertEqual(manifest.products.map { $0.name }, ["SwiftPM", "SwiftPM-auto", "SPMUtility"])
        XCTAssertEqual(manifest.products.map { $0.type }, [.library(.dynamic), .library(.automatic), .library(.automatic)])
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


// see: https://github.com/apple/swift-package-manager/blob/master/Examples/package-info/Sources/package-info/main.swift
let swiftCompiler: AbsolutePath = {
    let string: String
    #if os(macOS)
    string = try! Process.checkNonZeroExit(args: "xcrun", "--sdk", "macosx", "-f", "swiftc").spm_chomp()
    #else
    string = try! Process.checkNonZeroExit(args: "which", "swiftc").spm_chomp()
    #endif
    return AbsolutePath(string)
}()
