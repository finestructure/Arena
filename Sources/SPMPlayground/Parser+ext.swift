//
//  Parser+ext.swift
//  
//
//  Created by Sven A. Schmidt on 29/12/2019.
//

import Foundation
import PackageModel


typealias Requirement = PackageDependencyDescription.Requirement

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
        zip(literal("=="), .version).map { _, version in
            Requirement.exact(version)
        }
    }

    static var upToNextMajor: Parser<Requirement> {
        zip(literal(">="), .version).map { _, version in
            Requirement.upToNextMajor(from: version)
        }
    }

    static var range: Parser<Requirement> {
        zip(literal(">="), .version, literal("<"), .version)
            .map { _, minVersion, _, maxVersion in
                Requirement.range(minVersion..<maxVersion)
        }
    }

    static var noVersion: Parser<Requirement> {
        return Parser { str in
            return str.isEmpty ? DefaultRequirement : nil
        }
    }

    static var requirement: Parser<Requirement> {
        oneOf([.noVersion, .exact, .range, .upToNextMajor])
    }
}


extension Parser where A == Foundation.URL {
    static var url: Parser<Foundation.URL> {
        shortestOf([prefix(upTo: "=="), prefix(upTo: ">=")])
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
