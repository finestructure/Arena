//
//  File.swift
//  
//
//  Created by Sven A. Schmidt on 23/12/2019.
//

import ArgumentParser
import Foundation


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


extension Platform: ExpressibleByArgument { }
