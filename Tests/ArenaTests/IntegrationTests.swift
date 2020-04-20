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
            "https://github.com/finestructure/ArenaTest",
            "https://github.com/finestructure/Parser",
            "https://github.com/finestructure/Gala",
            "https://github.com/pointfreeco/swift-gen",
            "https://github.com/apple/swift-argument-parser",
            "https://github.com/davedelong/time",
            "https://github.com/alamofire/alamofire@from:5.0.0",
            "https://github.com/Peter-Schorn/Swift_Utilities"
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

