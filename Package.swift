// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Arena",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "arena", targets: ["ArenaCLI"]),
        .library(name: "ArenaCore", type: .dynamic, targets: ["ArenaCore"])
    ],
    dependencies: [
        .package(name: "swift-argument-parser",
                 url: "https://github.com/apple/swift-argument-parser", from: "0.2.0"),
        .package(url: "https://github.com/finestructure/Parser", from: "0.0.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(name: "Path.swift",
                 url: "https://github.com/mxcl/Path.swift.git", from: "1.0.0"),
        .package(url: "https://github.com/SwiftPackageIndex/SemanticVersion", from: "0.2.0"),
        .package(name: "SnapshotTesting",
                 url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.7.2"),
    ],
    targets: [
        .target(
            name: "ArenaCLI",
            dependencies: ["ArenaCore"]),
        .target(
            name: "ArenaCore",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Parser",
                .product(name: "Path", package: "Path.swift"),
                "SemanticVersion",
                "ShellOut"]),
        .testTarget(
            name: "ArenaTests",
            dependencies: ["ArenaCore", "SnapshotTesting"]),
    ]
)
