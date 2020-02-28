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

        self = dep
    }
}


extension Array: ExpressibleByArgument where Element == Dependency {
    public init?(argument: String) {
        let deps = argument
            .components(separatedBy: CharacterSet.whitespaces)
            .map(Dependency.init)
        guard deps.allSatisfy({ $0 != nil }) else { return nil }
        self = deps.compactMap({$0})
    }
}

