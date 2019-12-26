//
//  File.swift
//  
//
//  Created by Sven A. Schmidt on 23/12/2019.
//

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


extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
