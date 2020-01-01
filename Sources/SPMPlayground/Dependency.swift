//
//  Dependency.swift
//  
//
//  Created by Sven A. Schmidt on 29/12/2019.
//

import Foundation
import PackageModel
import Yaap


public struct Dependency: Equatable {
    let url: URL
    let requirement: Requirement

    init(url: URL, requirement: Requirement) {
        precondition(url.scheme != nil, "scheme must not be nil (i.e. one of https, http, file)")
        self.url = url
        self.requirement = requirement
    }

    init(url: URL, refSpec: RefSpec) {
        precondition(url.scheme != nil, "scheme must not be nil (i.e. one of https, http, file)")
        self.url = url
        switch refSpec {
            case .branch(let b):
                self.requirement = .branch(b)
            case .exact(let v):
                self.requirement = .exact(v)
            case .from(let v):
                self.requirement = .from(v)
            case .noVersion where url.isFileURL:
                self.requirement = .path
            case .noVersion:
                self.requirement = .from(SPMUtility.Version("0.0.0"))
            case .range(let r):
                self.requirement = .range(r)
            case .revision(let r):
                self.requirement = .revision(r)
        }
    }

    var packageClause: String {
        switch requirement {
            case .branch(let b):
                return #".package(url: "\#(url.absoluteString)", .branch("\#(b)"))"#
            case .exact(let v):
                return #".package(url: "\#(url.absoluteString)", .exact("\#(v)"))"#
            case .from(let v):
                return #".package(url: "\#(url.absoluteString)", from:"\#(v)")"#
            case .path:
                return #".package(path: "\#(url.path)")"#
            case .range(let r):
                return #".package(url: "\#(url.absoluteString)", "\#(r.lowerBound)"..<"\#(r.upperBound)")"#
            case .revision(let r):
                return #".package(url: "\#(url.absoluteString)", .revision("\#(r)"))"#
        }
    }
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

        let m = Parser.dependency.run(argument)

        guard let dep = m.result, m.rest.isEmpty else {
            throw ParseError.invalidFormat(argument)
        }

        self = dep
        arguments.removeFirst()
    }
}
