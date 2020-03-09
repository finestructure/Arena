//
//  File.swift
//  
//
//  Created by Sven A. Schmidt on 09/03/2020.
//

import Path


struct FileManager {
    var fileExists: (Path) -> Bool
}


extension FileManager {
    static let live = Self(
        fileExists: { $0.exists }
    )
}


