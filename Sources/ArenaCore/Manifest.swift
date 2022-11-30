import Foundation


// `Manifest` is mirroring what `dump-package` presumably renders into JSON
// https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html
// Mentioning this in particular with regards to optional values, like `platforms`
// vs mandatory ones like `products`
//
//Package(
//    name: String,
//    platforms: [SupportedPlatform]? = nil,
//    products: [Product] = [],
//    dependencies: [Package.Dependency] = [],
//    targets: [Target] = [],
//    swiftLanguageVersions: [SwiftVersion]? = nil,
//    cLanguageStandard: CLanguageStandard? = nil,
//    cxxLanguageStandard: CXXLanguageStandard? = nil
//)


struct Manifest: Decodable, Equatable {
    struct Platform: Decodable, Equatable {
        enum Name: String, Decodable, Equatable, CaseIterable {
            case macos
            case ios
            case tvos
            case watchos
        }
        var platformName: Name
        var version: String
    }
    struct Product: Decodable, Equatable {
        enum `Type`: String, CodingKey, CaseIterable {
            case executable
            case plugin
            case library
        }
        var name: String
        var type: `Type`
    }
    var name: String
    var platforms: [Platform]?
    var products: [Product]
    var swiftLanguageVersions: [String]?
}


extension Manifest.Product.`Type`: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.self)
        for k in Self.allCases {
            if let _ = try? container.decodeNil(forKey: k) {
                self = k
                return
            }

        }
        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: container.codingPath,
                                  debugDescription: "none of the required keys found"))
    }
}


extension Manifest.Platform {
    static func macos(_ version: String) -> Self { .init(platformName: .macos, version: version) }
    static func ios(_ version: String) -> Self { .init(platformName: .ios, version: version) }
    static func tvos(_ version: String) -> Self { .init(platformName: .tvos, version: version) }
    static func watchos(_ version: String) -> Self { .init(platformName: .watchos, version: version) }
}
