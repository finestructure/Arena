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
    struct Platforms {
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


