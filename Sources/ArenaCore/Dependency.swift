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
                self.requirement = .noVersion
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
            case .noVersion:
                return #".package(url: "\#(url.absoluteString)", from: "0.0.0")"#
        }
    }
}


extension Dependency: CustomStringConvertible {
    public var description: String {
        return "\(url.absoluteString) \(requirement)"
    }
}


extension String {
    var version: Version? {
        Parser.version.run(self).result
    }
}


func repository(for url: URL) -> Repository? {
    let path = url.path
    guard path.hasPrefix("/") else { return nil }
    let parts = path.dropFirst().split(separator: "/")
    guard parts.count == 2 else { return nil }
    let repo = parts[1].lowercased().hasSuffix(".git") ? parts[1].dropLast(".git".count) : parts[1]
    return Repository(owner: String(parts[0]), repository: String(repo))
}


let defaultRequirement: Requirement = .from("0.0.0")


func latestRequirement(for dependency: Dependency) -> Requirement {
    guard let repo = repository(for: dependency.url) else { return defaultRequirement }
    guard let version = latestReleaseRequest(for: repo)?.tagName.version
        else {
            print(" -> none found, defaulting to .from(0.0.0)")
            return .from("0.0.0")
    }
    print(" -> found \(version)")
    return .from(version)
}



extension Dependency: ExpressibleByArgument {
    public init?(argument: String) {
        let match = Parser.dependency.run(argument)

        guard let dep = match.result, match.rest.isEmpty else {
            return nil
        }

        let pathExists = dep.path.map(Current.fileManager.fileExists) ?? false
        let hasVersion = dep.requirement != .noVersion

        switch (dep.url.isFileURL, pathExists, hasVersion) {
            case (true, false, _):   // non-existant path   - try shorthand
                guard
                    let name = argument.split(separator: "@").first,
                    name.split(separator: "/").count == 2 else { return nil }
                let url = "https://github.com/\(argument)"
                guard let shorthand = Dependency(argument: url) else { return nil }
                self = shorthand
            case (false, _, true),   // url with version
                 (true, true, _):    // existing path       - keep as is
                self = dep
            case (false, _, false):  // url without version - look up version
                let req = latestRequirement(for: dep)
                self = Dependency(url: dep.url, requirement: req)
        }
    }
}
