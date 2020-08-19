//
//  Requirement.swift
//  
//
//  Created by Sven A. Schmidt on 31/12/2019.
//

import SemanticVersion


public enum Requirement: Equatable, Hashable {
    case exact(SemanticVersion)
    case range(Range<SemanticVersion>)
    case revision(String)
    case branch(String)
    case path
    case from(SemanticVersion)
    case noVersion

    public static func upToNextMajor(from version: SemanticVersion) -> Requirement {
        return .range(version..<SemanticVersion(version.major + 1, 0, 0))
    }
}


extension Requirement: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let v = try? container.decode(SemanticVersion.self, forKey: .exact) {
            self = .exact(v)
            return
        }

        if let v = try? container.decode(Range<SemanticVersion>.self, forKey: .range) {
            self = .range(v)
            return
        }

        if let v = try? container.decode(String.self, forKey: .revision) {
            self = .revision(v)
            return
        }

        if let v = try? container.decode(String.self, forKey: .branch) {
            self = .branch(v)
            return
        }

        if let _ = try? container.decode(String.self, forKey: .path) {
            self = .path
            return
        }

        if let v = try? container.decode(SemanticVersion.self, forKey: .from) {
            self = .from(v)
            return
        }

        if let _ = try? container.decode(SemanticVersion.self, forKey: .noVersion) {
            self = .noVersion
            return
        }

        let context = DecodingError.Context(codingPath: container.codingPath, debugDescription: "failed to decode Requirement, none of the keys matched")
        throw DecodingError.dataCorrupted(context)
    }

    enum CodingKeys: CodingKey {
        case exact
        case range
        case revision
        case branch
        case path
        case from
        case noVersion
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case .exact(let v):
                try container.encode(v, forKey: .exact)
            case .range(let v):
                try container.encode(v, forKey: .range)
            case .revision(let v):
                try container.encode(v, forKey: .revision)
            case .branch(let v):
                try container.encode(v, forKey: .branch)
            case .path:
                try container.encode("path", forKey: .path)
            case .from(let v):
                try container.encode(v, forKey: .from)
            case .noVersion:
                try container.encode("noVersion", forKey: .noVersion)
        }
    }
}

