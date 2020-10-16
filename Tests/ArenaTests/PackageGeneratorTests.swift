@testable import ArenaCore
import Path
import SnapshotTesting
import XCTest


class PackageGeneratorTests: XCTestCase {

    func test_productsClause() throws {
        let info: [(Dependency, PackageInfo)] = [
            (Dependency(url: URL(string: "https://github.com/finestructure/parser")!,
                        refSpec: .branch("main")),
             .init(name: "Parser", platforms: nil, libraries: ["Parser"])),
            (Dependency(url: URL(string: "https://github.com/finestructure/gala")!,
                        refSpec: .branch("main")),
             .init(name: "Gala", platforms: nil, libraries: ["Gala"])),
        ]
        assertSnapshot(matching: PackageGenerator.productsClause(info), as: .lines, record: false)
    }

    func test_platforms_stanza() throws {
        XCTAssertEqual(try getPackageInfo(in: fixturesDirectory/"Gala").platforms,
                       [.macos("10.15"), .ios("13.0"), .tvos("13.0"), .watchos("6.0")])
    }

}
