//
//  Dependency.swift
//  
//
//  Created by Sven A. Schmidt on 29/12/2019.
//

import ArgumentParser
import Foundation
import PackageModel
import Path
import Parser


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

    var path: Path? {
        requirement == .path ? Path(url: url) : nil
    }

    func checkoutDir(projectDir: Path) -> Path? {
        requirement == .path ? nil : projectDir/".build/checkouts"/url.lastPathComponent(dropExtension: "git")
    }

    var packageClause: String {
        switch requirement {
            case .branch(let b):
                return #".package(url: "\#(url.absoluteString)", .branch("\#(b)"))"#
            case .exact(let v):
                return #".package(url: "\#(url.absoluteString)", .exact("\#(v)"))"#
            case .from(let v):
                return #".package(url: "\#(url.absoluteString)", from: "\#(v)")"#
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


extension Dependency: ExpressibleByArgument {
    public init?(argument: String) {
        let m = Parser.dependency.run(argument)

        guard let dep = m.result, m.rest.isEmpty else {
            return nil
        }

        let pathExists = dep.path.map(Current.fileManager.fileExists) ?? false
        guard dep.url.isFileURL, !pathExists else {
            self = dep
            return
        }

        // we have a dependency that has a file url but the
        // path doesn't exist - try a Github shorthand instead
        guard
            let name = argument.split(separator: "@").first,
            name.split(separator: "/").count == 2 else { return nil }
        let url = "https://github.com/\(argument)"
        guard let shorthand = Dependency(argument: url) else { return nil }
        self = shorthand
    }
}
