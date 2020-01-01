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


extension Parser where A == RefSpec {
    static var branch: Parser<RefSpec> {
        zip(literal("@branch:"), branchName).map { RefSpec.branch(String($0.1)) }
    }

    static var exact: Parser<RefSpec> {
        zip(literal("@"), .version).map { RefSpec.exact($0.1) }
    }

    static var from: Parser<RefSpec> {
        zip(literal("@from:"), .version).map { RefSpec.from($0.1) }
    }

    static var noVersion: Parser<RefSpec> {
        Parser<Void>.end.map { RefSpec.noVersion }
    }

    static var range: Parser<RefSpec> {
        oneOf([
            zip(literal("@"), .version, string("..<"), .version),
            zip(literal("@"), .version, string("..."), .version)
        ]).map { _, minVersion, rangeOp, maxVersion in
            rangeOp == "..<"
                ? RefSpec.range(minVersion..<maxVersion)
                : RefSpec.range(minVersion..<Version(maxVersion.major, maxVersion.minor, maxVersion.patch + 1))
        }
    }

    static var revision: Parser<RefSpec> {
        zip(literal("@revision:"), prefix(charactersIn: AllowedRevisionCharacters))
            .map { RefSpec.revision(String($0.1)) }
    }

    static var refSpec: Parser<RefSpec> {
        // append ".end" to all parsers to ensure they are exhaustive
        oneOf([.branch, .exact, .from, .noVersion, .range, .revision].map(appendEnd))
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
                    return .never
                }
        }
    }
}


extension Parser where A == Dependency {
    static var dependency: Parser<Dependency> {
        zip(.url, .refSpec).map { Dependency(url: $0.0, refSpec: $0.1) }
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
