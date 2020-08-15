//
//  File.swift
//  
//
//  Created by Sven A. Schmidt on 13/03/2020.
//

//import PackageModel
import Parser
import SemanticVersion


extension String {
    public var dependency: Dependency? {
        Parser.dependency.run(self).result
    }

    public var version: SemanticVersion? {
        Parser.version.run(self).result
    }
}
