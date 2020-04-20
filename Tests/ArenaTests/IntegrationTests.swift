//
//  IntegrationTests.swift
//  ArenaTests
//
//  Created by Sven A. Schmidt on 02/03/2020.
//

@testable import ArenaCore
import XCTest


class IntegrationTests: XCTestCase {
    override func setUp() {
        Current = .live
    }

    func test_spm_packages() throws {
        let dependencies = [
            // test some packages that we want to make sure work (e.g. because they're
            // used in docs and refs) or because they've had issues in the past
            // (regression testing)
            "finestructure/ArenaTest",
            "finestructure/Parser",
            "finestructure/Gala",
            "pointfreeco/swift-gen",
            "apple/swift-argument-parser",
            "davedelong/time",
            "alamofire/alamofire",
            "Peter-Schorn/Swift_Utilities"
        ]

        try dependencies.forEach { dep in
            let arena = try Arena.parse([
                dep,
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

            print("🧪 Testing dependency \(dep)")
            try arena.run(progress: progress)

            wait(for: [exp], timeout: 10)
        }
    }

}

