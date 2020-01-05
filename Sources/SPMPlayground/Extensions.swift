//
//  File.swift
//  
//
//  Created by Sven A. Schmidt on 23/12/2019.
//

import Foundation
import Path
import ShellOut
import Yaap


@discardableResult
public func shellOut(to command: ShellOutCommand, at path: Path) throws -> String {
    try shellOut(to: command, at: "\(path)", outputHandle: nil, errorHandle: nil)
}


extension ShellOutCommand {
    public static func openFile(at path: Path) -> ShellOutCommand {
        return ShellOutCommand(string: "open \(path)")
    }
}


extension Optional: CustomStringConvertible where Wrapped == String {
    public var description: String {
        switch self {
            case let .some(value): return value
            case .none: return "nil"
        }
    }

}


extension Optional: ArgumentType where Wrapped == String {
    public init(arguments: inout [String]) throws {
        self = arguments.first
        if !arguments.isEmpty {
            arguments.removeFirst()
        }
    }
}


extension Path: ArgumentType {
    public init(arguments: inout [String]) throws {
        guard let arg = arguments.first else {
            throw ParseError.missingArgument
        }
        guard let path = Path(arg) else {
            throw ParseError.invalidFormat(arg)
        }
        arguments.removeFirst()
        self = path
    }
}
