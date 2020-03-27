//
//  IntegrationTests.swift
//  ArenaTests
//
//  Created by Sven A. Schmidt on 02/03/2020.
//

@testable import ArenaCore
import XCTest


class IntegrationTests: XCTestCase {
    
    #if swift(>=5.2)
    func test_ArenaTest() throws {
        try XCTSkipUnless(ProcessInfo().hostName == "luna.local", "fails on CI, only run locally")

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
    #endif
    
    #if swift(>=5.2)
    func test_Gen() throws {
        try XCTSkipUnless(ProcessInfo().hostName == "luna.local", "fails on CI, only run locally")

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
    #endif

}

