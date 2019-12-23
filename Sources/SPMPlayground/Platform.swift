//
//  File.swift
//  
//
//  Created by Sven A. Schmidt on 23/12/2019.
//

import Foundation
import Yaap


public enum Platform: String {
    case ios
    case macos
    case tvos
}


extension Platform: CustomStringConvertible {
    public var description: String {
        switch self {
            case .ios: return "ios"
            case .macos: return "macos"
            case .tvos: return "tvos"
        }
    }
}


extension Platform: ArgumentType {
    public init(arguments: inout [String]) throws {
        guard let argument = arguments.first else {
            throw ParseError.missingArgument
        }

        guard let value = Platform.init(rawValue: argument) else {
            throw ParseError.invalidFormat(argument)
        }

        self = value
        arguments.removeFirst()
    }
}


