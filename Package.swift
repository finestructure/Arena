// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Arena",
    products: [
        .executable(name: "arena", targets: ["Arena-CLI"]),
        .library(name: "Arena", targets: ["Arena"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager", from: "0.5.0"),
        .package(url: "https://github.com/finestructure/Parser", from: "0.0.0"),
        .package(url: "https://github.com/hartbit/Yaap.git", from: "1.0.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/mxcl/Path.swift.git", from: "0.13.0"),
    ],
    targets: [
        .target(
            name: "Arena-CLI",
            dependencies: ["Arena"]),
        .target(
            name: "Arena",
            dependencies: ["Parser", "Path", "ShellOut", "SwiftPM-auto", "Yaap"]),
        .testTarget(
            name: "ArenaTests",
            dependencies: ["Arena"]),
    ]
)
