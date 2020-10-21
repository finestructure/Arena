//
//  File.swift
//  
//
//  Created by Sven A. Schmidt on 20/12/2019.
//

import Foundation
import Path


public struct PackageInfo {
    var name: String
    var platforms: [Manifest.Platform]?
    var libraries: [String]
}


func dumpPackage(at path: Path) throws -> Manifest {
    let json = try shellOut(to: .init(string: "swift package dump-package"), at: path)
    return try JSONDecoder().decode(Manifest.self, from: Data(json.utf8))
}


public func getPackageInfo(in directory: Path) throws -> PackageInfo {
    let manifest = try dumpPackage(at: directory)
    let libs = manifest.products.filter { p in
        if case .library = p.type {
            return true
        } else {
            return false
        }
    }
    .map { $0.name }
    return PackageInfo(name: manifest.name, platforms: manifest.platforms, libraries: libs)
}


extension Foundation.URL {
    public func lastPathComponent(dropExtension ext: String) -> String {
        if pathExtension == ext {
            return deletingPathExtension().lastPathComponent
        }
        return lastPathComponent
    }
}


func zip<A, B>(_ a: A?, _ b: B?) -> (A, B)? {
    if let a = a, let b = b {
        return (a, b)
    } else {
        return nil
    }
}


