//
//  Requirement.swift
//  
//
//  Created by Sven A. Schmidt on 31/12/2019.
//

import PackageModel


public enum Requirement: Equatable {
    case exact(Version)
    case range(Range<Version>)
    case revision(String)
    case branch(String)
    case noVersion

    public static func upToNextMajor(from version: Version) -> Requirement {
        return .range(version..<Version(version.major + 1, 0, 0))
    }
}


extension Requirement {
    public var dependencyClause: String {
        // "1.2.3"..<"1.2.6"
        // .exact("1.2.3")
        // .revision("123...7890")
        // .branch("develop")
        switch self {
            case .branch(let s): return ".branch(\"\(s)\")"
            case .exact(let v): return ".exact(\"\(v)\")"
            case .range(let r): return "\"\(r.lowerBound)\"..<\"\(r.upperBound)\""
            case .revision(let s): return ".revision(\"\(s)\")"
            case .noVersion: return ".noVersion"
        }
    }
}
