//
//  Parser+ext.swift
//  
//
//  Created by Sven A. Schmidt on 29/12/2019.
//

import Foundation
import PackageModel


let DefaultRequirement = Requirement.upToNextMajor(from: Version(0, 0, 0))


extension Parser where A == Version {
    static var version: Parser<Version> {
        zip(int, literal("."), int, literal("."), int).map { major, _, minor, _, patch in
            Version(major, minor, patch)
        }
    }
}


extension Parser where A == Requirement {
    static var exact: Parser<Requirement> {
        oneOf([
            zip(literal("=="), .version),
            zip(literal("@"), .version)
        ])
            .map { _, version in
                Requirement.exact(version)
        }
    }

    static var upToNextMajor: Parser<Requirement> {
        oneOf([
            zip(literal(">="), .version),
            zip(literal("@from:"), .version)
        ])
            .map { _, version in
                Requirement.upToNextMajor(from: version)
        }
    }

    static var range: Parser<Requirement> {
        oneOf([
            zip(literal(">="), .version, string("<"), .version),
            zip(literal("@"), .version, string("..<"), .version),
            zip(literal("@"), .version, string("..."), .version)
        ])
            .map { _, minVersion, rangeOp, maxVersion in
                rangeOp == "..."
                    ? Requirement.range(minVersion..<Version(maxVersion.major, maxVersion.minor, maxVersion.patch + 1))
                    : Requirement.range(minVersion..<maxVersion)
        }
    }

    static var noVersion: Parser<Requirement> {
        Parser<Void>.end.map { DefaultRequirement }
    }

    static var requirement: Parser<Requirement> {
        // append ".end" to all requirement parsers to ensure they are exhaustive
        let reqs = [.noVersion, .exact, .range, .upToNextMajor].map {
            zip($0, .end).flatMap { req, _ in always(req) }
        }
        return oneOf(reqs)
    }
}


extension Parser where A == Foundation.URL {
    static var url: Parser<Foundation.URL> {
        shortestOf([prefix(upTo: "=="), prefix(upTo: ">="), prefix(upTo: "@")])
            .map(String.init)
            .flatMap {
                if let url = URL(string: $0) {
                    return always(url)
                } else {
                    return Parser<Foundation.URL>.never
                }
        }
    }
}


extension Parser where A == Dependency {
    static var dependency: Parser<Dependency> {
        zip(.url, .requirement).map { Dependency(url: $0.0, requirement: $0.1) }
    }
}
