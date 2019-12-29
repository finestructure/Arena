//
//  Dependency.swift
//  
//
//  Created by Sven A. Schmidt on 29/12/2019.
//

import Foundation
import PackageModel
import Yaap


typealias Requirement = PackageDependencyDescription.Requirement


public struct Dependency: Equatable {
    let url: URL
    let requirement: Requirement
}


extension Dependency: CustomStringConvertible {
    public var description: String {
        return "\(url.absoluteString) \(requirement)"
    }
}


extension Dependency: ArgumentType {
    public init(arguments: inout [String]) throws {
        guard let argument = arguments.first else {
            throw ParseError.missingArgument
        }

        let res = Parser.dependency.run(argument)

        guard let dep = res.match, res.rest.isEmpty else {
            throw ParseError.invalidFormat(argument)
        }

        self = dep
        arguments.removeFirst()
    }
}


extension Requirement {
    public var dependencyClause: String {
        // "1.2.3"..<"1.2.6"
        // .exact("1.2.3")
        // .revision("123...7890")
        // .branch("develop")
        switch self {
            case .branch(let s): return ".branch(\"\(s)\")"
            case .exact(let v): return ".exact(\"\(v)\")"
            case .range(let r): return "\"\(r.lowerBound)\"..<\"\(r.upperBound)\""
            case .revision(let s): return ".revision(\"\(s)\")"
            case .localPackage: return "localPackage (not implemented)"
        }
    }
}
