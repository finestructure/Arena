// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SPMPlayground",
            dependencies: ["Path", "ShellOut", "Yaap"]),
    ]
)
