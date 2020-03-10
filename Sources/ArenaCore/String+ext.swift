//
//  File.swift
//  
//
//  Created by Sven A. Schmidt on 10/03/2020.
//


import PackageModel
import Parser


extension String {
    var version: Version? {
        Parser.version.run(self).result
    }
}

