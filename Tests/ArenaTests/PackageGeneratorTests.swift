@testable import ArenaCore
import Path
import SnapshotTesting
import XCTest


class PackageGeneratorTests: XCTestCase {

    func test_productsClause() throws {
        let info: [(PackageInfo, PackageIdentifier)] = [
            (.init(name: "Parser", platforms: nil, libraries: ["Parser"]),
             .init(url: "https://github.com/finestructure/Parser")),
            (.init(name: "Gala", platforms: nil, libraries: ["Gala"]),
             .init(url: "https://github.com/finestructure/gala")),
            (.init(name: "Alias", platforms: nil, libraries: ["Alias"]),
             .init(url: "https://github.com/p-x9/AliasMacro")),
        ]
        XCTAssertEqual(PackageGenerator.productsClause(info), """
            .product(name: "Parser", package: "Parser"),
            .product(name: "Gala", package: "gala"),
            .product(name: "Alias", package: "AliasMacro")
            """)
    }

    func test_mergePlatforms() throws {
        let p1 = PackageGenerator.Platforms(iOS: .ios("13.0"),
                                            macOS: .macos("10.15"))
        let p2 = PackageGenerator.Platforms(iOS: .ios("10.0"),
                                            tvOS: .tvos("14.0"))
        XCTAssertEqual(PackageGenerator.mergePlatforms([p1, p2]),
                       .init(iOS: .ios("13.0"),
                             macOS: .macos("10.15"),
                             tvOS: .tvos("14.0"),
                             watchOS: nil))
    }

    func test_platforms_stanza() throws {
        let platforms = PackageGenerator.Platforms(iOS: .ios("13.0"),
                                                   macOS: .macos("10.15"),
                                                   tvOS: .tvos("13.0"),
                                                   watchOS: .watchos("6.0"))
        assertSnapshot(matching: PackageGenerator.platformsClause(platforms),
                       as: .lines,
                       record: false)
    }

    func test_content() throws {
        assertSnapshot(matching: PackageGenerator.content(libraries: ["A", "B"]),
                       as: .lines,
                       record: false)
    }

    func test_content_skipInternalLibs() throws {
        assertSnapshot(matching: PackageGenerator.content(libraries: ["_A", "B"]),
                       as: .lines,
                       record: false)
    }

    func test_contentsXCPlayground() throws {
        assertSnapshot(matching: PackageGenerator.contentsXCPlayground(platform: .macos),
                       as: .lines,
                       record: false)
    }

}
