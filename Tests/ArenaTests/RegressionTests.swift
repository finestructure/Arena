import XCTest

@testable import ArenaCore

import Path


final class RegressionTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        Current = .mock
    }

#if swift(>=5.7)  // test can only run on 5.7+ due to manifest tools-version
    func test_issue_90() throws {
        // https://github.com/finestructure/Arena/issues/90
        // macCatalyst platform in manifest
        XCTAssertEqual(try getPackageInfo(in: fixturesDirectory/"Issue-90").platforms,
                       [.macos("12.0"), .macCatalyst("15.0"), .ios("15.0"), .watchos("8.0"), .tvos("15.0")])

    }
#endif

}
