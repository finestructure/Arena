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
