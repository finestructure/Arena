//
//  IntegrationTests.swift
//  ArenaTests
//
//  Created by Sven A. Schmidt on 02/03/2020.
//

@testable import ArenaCore
import XCTest


class IntegrationTests: XCTestCase {

    func test_ArenaTest() throws {
        let dependencies = [
            "https://github.com/finestructure/ArenaTest@0.0.3",
            "finestructure/parser",
            "finestructure/gala",
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

            try arena.run(progress: progress)

            wait(for: [exp], timeout: 10)
        }
    }

}

