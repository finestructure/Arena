// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FSPlaygrounds",
    products: [
        .executable(name: "playgrounds", targets: ["FSPlaygrounds"])
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/Commander.git", from: "0.8.0"),
        .package(url: "https://github.com/mxcl/Path.swift.git", from: "0.13.0"),
        .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "FSPlaygrounds",
            dependencies: ["Commander", "Path", "ShellOut"]),
        .testTarget(
            name: "FSPlaygroundsTests",
            dependencies: ["FSPlaygrounds"]),
    ]
)
