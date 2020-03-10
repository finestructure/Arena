//
//  Environment.swift
//  
//
//  Created by Sven A. Schmidt on 09/03/2020.
//

struct Environment {
    var fileManager: FileManager
}


extension Environment {
    static let live = Self(
        fileManager: .live
    )
}


#if DEBUG
var Current = Environment.live
#else
let Current = Environment.live
#endif
