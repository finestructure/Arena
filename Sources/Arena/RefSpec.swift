//
//  RefSpec.swift
//  
//
//  Created by Sven A. Schmidt on 01/01/2020.
//

import PackageModel


enum RefSpec: Equatable {
    case branch(String)
    case exact(Version)
    case from(Version)
    case noVersion
    case range(Range<Version>)
    case revision(String)
}
