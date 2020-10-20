enum PackageGenerator {
    static func productsClause(_ info: [(Dependency, PackageInfo)]) -> String {
        info
            .flatMap { pkg in pkg.1.libraries.map { (package: pkg.1.name, library: $0) } }
            .map {
            """
            .product(name: "\($0.library)", package: "\($0.package)")
            """
        }.joined(separator: ",\n")
    }
}

extension PackageGenerator {
    struct Platforms: Equatable {
        var iOS: Manifest.Platform?
        var macOS: Manifest.Platform?
        var tvOS: Manifest.Platform?
        var watchOS: Manifest.Platform?

        init(iOS: Manifest.Platform? = nil,
             macOS: Manifest.Platform? = nil,
             tvOS: Manifest.Platform? = nil,
             watchOS: Manifest.Platform? = nil) {
            self.iOS = iOS
            self.macOS = macOS
            self.tvOS = tvOS
            self.watchOS = watchOS
        }

        var all: [Manifest.Platform] {
            [self.iOS, self.macOS, self.tvOS, self.watchOS].compactMap { $0 }
        }

        func merged(with other: Platforms) -> Platforms {
            .init(iOS: max(iOS, other.iOS),
                  macOS: max(macOS, other.macOS),
                  tvOS: max(tvOS, other.tvOS),
                  watchOS: max(watchOS, other.watchOS))
        }
    }

    static func mergePlatforms(_ platforms: [Platforms]) -> Platforms {
        platforms.reduce(platforms.first!) { result, next in
            result.merged(with: next)
        }
    }

    static func platformsClause(_ platforms: Platforms) -> String {
        //platforms: [
        //    .ios("13.0"),
        //    .macos("10.15"),
        //    .tvos("13.0"),
        //    .watchos("6.0")
        //],
        """
        platforms: [
            \(platforms.all.map { #".\#($0.platformName)("\#($0.version)")"# }
                .joined(separator: ",\n    "))
        ]
        """
    }
}


func max(_ a: Manifest.Platform, _ b: Manifest.Platform) -> Manifest.Platform {
    precondition(a.platformName == b.platformName)
    switch (PlatformVersion(string: a.version), PlatformVersion(string: b.version)) {
        case (.none, .none):
            fatalError("both platform versions are invalid: \(a.version), \(b.version)")
        case (.some, .none):
            return a
        case (.none, .some):
            return b
        case let (.some(va), .some(vb)):
           return va > vb ? a : b
    }
}


func max(_ a: Manifest.Platform?, _ b: Manifest.Platform?) -> Manifest.Platform? {
    switch (a, b) {
        case let (.some(a), .some(b)):
            return max(a, b)
        case let (.some(a), .none):
            return a
        case let (.none, .some(b)):
            return b
        case (.none, .none):
            return nil
    }
}
