//
//  LocalIntegrationTests.swift
//  ArenaTests
//
//  Created by Sven A. Schmidt on 31/03/2020.
//

@testable import ArenaCore
import XCTest


class LocalIntegrationTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo().hostName == "luna.local", "fails on CI, only run locally")
        Current = .live
    }

    func test_ouput() throws {
        let output = OutputListener()
        output.openConsolePipe()

        let arena = try Arena.parse([
            "https://github.com/finestructure/ArenaTest@0.0.3",
            "--name=ArenaIntegrationTest",
            "--force",
            "--skip-open"])
        try arena.run()

        let expectation = """
                ➡️  Package: https://github.com/finestructure/ArenaTest @ exact(0.0.3)
                🔧 Resolving package dependencies ...
                📔 Libraries found: ArenaTest
                🔨 Building package dependencies ...
                ✅ Created project in folder 'ArenaIntegrationTest'
                Run
                  open ArenaIntegrationTest/ArenaIntegrationTest.xcworkspace
                to open the project in Xcode

                """
        let predicate = NSPredicate { _,_  in
            output.contents == expectation
        }
        let exp = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        wait(for: [exp], timeout: 10)
        XCTAssertEqual(output.contents, expectation)

        output.closeConsolePipe()
    }

    // FIXME: fails on CI but shouldn't
    // https://github.com/finestructure/Arena/issues/43
    func test_Gen() throws {
        let arena = try Arena.parse([
            "https://github.com/pointfreeco/swift-gen@0.2.0",
            "--name=ArenaIntegrationTest",
            "--force",
            "--skip-open"])

        let exp = self.expectation(description: "exp")

        let progress: ProgressUpdate = { stage, _ in
            print("progress: \(stage)")
            if stage == .completed {
                exp.fulfill()
            }
        }

        try arena.run(progress: progress)

        wait(for: [exp], timeout: 10)
    }

    // Can't run on CI due to lacking ssh credentials
    func test_git_protocol() throws {
        let arena = try Arena.parse([
            "git@github.com:finestructure/ArenaTest@0.0.3",
            "--name=ArenaIntegrationTest",
            "--force",
            "--skip-open"])

        let exp = self.expectation(description: "exp")

        let progress: ProgressUpdate = { stage, _ in
            print("progress: \(stage)")
            if stage == .completed {
                exp.fulfill()
            }
        }

        try arena.run(progress: progress)

        wait(for: [exp], timeout: 10)
    }

}
