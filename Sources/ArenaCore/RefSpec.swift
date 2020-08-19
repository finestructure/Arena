//
//  RefSpec.swift
//  
//
//  Created by Sven A. Schmidt on 01/01/2020.
//

import SemanticVersion


enum RefSpec: Equatable {
    case branch(String)
    case exact(SemanticVersion)
    case from(SemanticVersion)
    case noVersion
    case range(Range<SemanticVersion>)
    case revision(String)
}
