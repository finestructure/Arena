//
//  Scheme.swift
//  
//
//  Created by Sven A. Schmidt on 02/01/2020.
//


enum Scheme: String, CaseIterable {
    case https = "https://"
    case http = "http://"
    case file = "file://"
    case empty = ""
}
