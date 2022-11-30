import Foundation
import Path
import SemanticVersion
import XCTest


extension SemanticVersion: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = SemanticVersion(value)!
    }
}


private func _fixturesDirectory(path: String = #file) -> URL {
    let url = URL(fileURLWithPath: path)
    let testsDir = url.deletingLastPathComponent().deletingLastPathComponent()
    let res = testsDir.appendingPathComponent("Fixtures")
    return res
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


    func loadFixture(_ fixture: String) throws -> Data {
        let url = fixturesDirectory/fixture
        return try Data(contentsOf: url)
    }

    var fixturesDirectory: Path {
        Path(url: _fixturesDirectory())!
    }

}


