import XCTest

@testable import ArenaCore

final class ManifestTests: XCTestCase {

    func test_decode_v5_5() throws {
        let json = try loadFixture("manifest-5.5.json")
        XCTAssertNoThrow(
            try JSONDecoder().decode(Manifest.self, from: json)
        )
    }

    func test_decode_v5_7() throws {
        let json = try loadFixture("manifest-5.7.json")
        XCTAssertNoThrow(
            try JSONDecoder().decode(Manifest.self, from: json)
        )
    }

}
