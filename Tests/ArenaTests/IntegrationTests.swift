//
//  IntegrationTests.swift
//  ArenaTests
//
//  Created by Sven A. Schmidt on 02/03/2020.
//

@testable import ArenaCore
import SnapshotTesting
import XCTest


class IntegrationTests: XCTestCase {
    override func setUp() {
        Current = .live
    }

    func test_output() throws {
        let arena = try Arena.parse([
            "https://github.com/finestructure/ArenaTest@0.0.3",
            "-o",
            "ArenaIntegrationTest",
            "--force",
            "--skip-open"])

        let exp = self.expectation(description: "exp")

        var output = ""
        let progress = { (stage: ArenaCore.Progress.Stage, msg: String) in
            output += msg + "\n"
            if stage == .completed {
                exp.fulfill()
            }
        }

        try arena.run(progress: progress)

        wait(for: [exp], timeout: 10)

        assertSnapshot(matching: output, as: .lines, record: false)
    }

    func test_packages() throws {
        let isRunningInCI = ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW")
        try XCTSkipIf(isRunningInCI)

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
                "--force",
                "--skip-open"])

            let exp = self.expectation(description: dep)

            let progress = { (stage: ArenaCore.Progress.Stage, msg: String) in
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

    func test_git_protocol() throws {
        let isRunningInCI = ProcessInfo.processInfo.environment.keys.contains("GITHUB_WORKFLOW")
        try XCTSkipIf(isRunningInCI)

        let arena = try Arena.parse([
            "git@github.com:finestructure/ArenaTest@0.0.3",
            "--force",
            "--skip-open"])

        let exp = self.expectation(description: "exp")

        let progress = { (stage: ArenaCore.Progress.Stage, msg: String) in
            print("progress: \(stage)")
            if stage == .completed {
                exp.fulfill()
            }
        }

        try arena.run(progress: progress)

        wait(for: [exp], timeout: 10)
    }

}

