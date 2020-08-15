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
    var path: Path
    var libraries: [String]
}


public func getPackageInfo(for package: Path) throws -> PackageInfo {
//    let path = AbsolutePath(package.string)
//    let manifest = try ManifestLoader.loadManifest(packagePath: path,
//                                                   swiftCompiler: swiftCompiler,
//                                                   packageKind: .remote)
//    let libs = manifest.products.filter { p in
//        if case .library = p.type {
//            return true
//        } else {
//            return false
//        }
//    }
//    .map { $0.name }
    let name = "" // FIXME: was manifest.name
    let path = package  // FIXME: was AbsolutePath(package.string)
    let libs = [String]()  // FIXME
    return PackageInfo(name: name, path: path, libraries: libs)
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
