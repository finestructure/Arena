//
//  Dependency.swift
//  
//
//  Created by Sven A. Schmidt on 29/12/2019.
//

import Foundation
import Yaap


public struct Dependency: Equatable {
    let url: URL
    let requirement: Requirement

    var packageClause: String {
        switch requirement {
            case .noVersion where url.isFileURL || url.scheme == nil:
                return ".package(path: \"\(url.absoluteString)\")"
            case .noVersion:
                return ".package(url: \"\(url.absoluteString)\", \(DefaultRequirement.dependencyClause))"
            default:
                return ".package(url: \"\(url.absoluteString)\", \(requirement.dependencyClause))"
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
