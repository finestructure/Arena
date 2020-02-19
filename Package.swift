// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Arena",
    products: [
        .executable(name: "arena", targets: ["ArenaCLI"]),
        .library(name: "ArenaCore", targets: ["ArenaCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager", .revision("swift-5.2-DEVELOPMENT-SNAPSHOT-2020-02-18-a")),
        .package(url: "https://github.com/finestructure/Parser", from: "0.0.0"),
        .package(url: "https://github.com/hartbit/Yaap.git", from: "1.0.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/mxcl/Path.swift.git", from: "0.13.0"),
    ],
    targets: [
        .target(
            name: "ArenaCLI",
            dependencies: ["ArenaCore"]),
        .target(
            name: "ArenaCore",
            dependencies: ["Parser", "Path", "ShellOut", "SwiftPM-auto", "Yaap"]),
        .testTarget(
            name: "ArenaTests",
            dependencies: ["ArenaCore"]),
    ]
)
