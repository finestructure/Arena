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
    case path
    case from(Version)

    public static func upToNextMajor(from version: Version) -> Requirement {
        return .range(version..<Version(version.major + 1, 0, 0))
    }
}
