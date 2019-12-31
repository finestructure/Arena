//
//  Parser+ext.swift
//  
//
//  Created by Sven A. Schmidt on 29/12/2019.
//

import Foundation
import PackageModel


let DefaultRequirement = Requirement.upToNextMajor(from: Version(0, 0, 0))

// https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-check-ref-format.html
let AllowedBranchCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: ".-@/"))
let AllowedStartBranchCharacters = AllowedBranchCharacters.subtracting(CharacterSet(charactersIn: "/"))
let AllowedEndBranchCharacters = AllowedBranchCharacters.subtracting(CharacterSet(charactersIn: "/."))

let AllowedRevisionCharacters = CharacterSet.whitespacesAndNewlines.inverted


extension Parser where A == Version {
    static var version: Parser<Version> {
        zip(int, literal("."), int, literal("."), int).map { major, _, minor, _, patch in
            Version(major, minor, patch)
        }
    }
}


extension Parser where A == Requirement {
    static var branch: Parser<Requirement> {
        zip(literal("@branch:"), branchName).map { Requirement.branch(String($0.1)) }
    }

    static var exact: Parser<Requirement> {
        zip(literal("@"), .version).map { Requirement.exact($0.1) }
    }

    static var noVersion: Parser<Requirement> {
        Parser<Void>.end.map { DefaultRequirement }
    }

    static var range: Parser<Requirement> {
        oneOf([
            zip(literal("@"), .version, string("..<"), .version),
            zip(literal("@"), .version, string("..."), .version)
        ]).map { _, minVersion, rangeOp, maxVersion in
            rangeOp == "..<"
                ? Requirement.range(minVersion..<maxVersion)
                : Requirement.range(minVersion..<Version(maxVersion.major, maxVersion.minor, maxVersion.patch + 1))
        }
    }

    static var revision: Parser<Requirement> {
        zip(literal("@revision:"), prefix(charactersIn: AllowedRevisionCharacters))
            .map { Requirement.revision(String($0.1)) }
    }

    static var upToNextMajor: Parser<Requirement> {
        zip(literal("@from:"), .version).map { Requirement.upToNextMajor(from: $0.1) }
    }

    static var requirement: Parser<Requirement> {
        // append ".end" to all requirement parsers to ensure they are exhaustive
        oneOf([.branch, .exact, .noVersion, .range, .revision, .upToNextMajor].map(appendEnd))
    }
}


extension Parser where A == Foundation.URL {
    static var url: Parser<Foundation.URL> {
        prefix(upTo: "@")
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


let branchName = zip(
    char(in: AllowedStartBranchCharacters),
    prefix(charactersIn: AllowedBranchCharacters)
).flatMap { res -> Parser<Substring> in
    let (head, tail) = res
    guard let last = tail.last, AllowedEndBranchCharacters.contains(character: last) else {
        return .never
    }
    return always(String(head) + tail)
}
