// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SPMPlayground",
    products: [
        .executable(name: "spm-playground", targets: ["SPMPlayground"])
    ],
    dependencies: [
        .package(url: "https://github.com/mxcl/Path.swift.git", from: "0.13.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
        .package(url: "https://github.com/hartbit/Yaap.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SPMPlayground",
            dependencies: ["Path", "ShellOut", "Yaap"]),
        .testTarget(
            name: "SPMPlaygroundTests",
            dependencies: ["SPMPlayground"]),
    ]
)
