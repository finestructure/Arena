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
            (Dependency(url: URL(string: "https://github.com/p-x9/AliasMacro")!,
                        refSpec: .exact(.init(0, 2, 1))),
             .init(name: "Alias", platforms: nil, libraries: ["Alias"])),
        ]
        assertSnapshot(matching: PackageGenerator.productsClause(info),
                       as: .lines,
                       record: false)
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
