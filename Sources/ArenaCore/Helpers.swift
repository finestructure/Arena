//
//  File.swift
//  
//
//  Created by Sven A. Schmidt on 20/12/2019.
//

import Foundation
//import PackageLoading
import Path
//import Workspace


// see: https://github.com/apple/swift-package-manager/blob/master/Examples/package-info/Sources/package-info/main.swift
let swiftCompiler: AbsolutePath = {
    let string: String
    #if os(macOS)
    string = try! Process.checkNonZeroExit(args: "xcrun", "--sdk", "macosx", "-f", "swiftc").spm_chomp()
    #else
    string = try! Process.checkNonZeroExit(args: "which", "swiftc").spm_chomp()
    #endif
    return AbsolutePath(string)
}()


public struct PackageInfo {
    var name: String
    var path: AbsolutePath
    var libraries: [String]
}


public func getPackageInfo(for package: Path) throws -> PackageInfo {
    let path = AbsolutePath(package.string)
    let manifest = try ManifestLoader.loadManifest(packagePath: path,
                                                   swiftCompiler: swiftCompiler,
                                                   packageKind: .remote)
    let libs = manifest.products.filter { p in
        if case .library = p.type {
            return true
        } else {
            return false
        }
    }
    .map { $0.name }
    return PackageInfo(name: manifest.name, path: path, libraries: libs)
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
