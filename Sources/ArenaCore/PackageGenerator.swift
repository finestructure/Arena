import Path

struct PackageIdentifier {
    var id: String

    init(url: String) {
        self.id = Self.computeDefaultName(fromLocation: url)
    }

    static func computeDefaultName(fromLocation url: String) -> String {
        #if os(Windows)
        let isSeparator: (Character) -> Bool = { $0 == "/" || $0 == "\\" }
        #else
        let isSeparator: (Character) -> Bool = { $0 == "/" }
        #endif

        // Get the last path component of the URL.
        // Drop the last character in case it's a trailing slash.
        var endIndex = url.endIndex
        if let lastCharacter = url.last, isSeparator(lastCharacter) {
            endIndex = url.index(before: endIndex)
        }

        let separatorIndex = url[..<endIndex].lastIndex(where: isSeparator)
        let startIndex = separatorIndex.map { url.index(after: $0) } ?? url.startIndex
        var lastComponent = url[startIndex ..< endIndex]

        // Strip `.git` suffix if present.
        if lastComponent.hasSuffix(".git") {
            lastComponent = lastComponent.dropLast(4)
        }

        return String(lastComponent)
    }

}

enum PackageGenerator {
    static func productsClause(_ info: [(PackageInfo, PackageIdentifier)]) -> String {
        var clauses = [String]()
        for (pkgInfo, pkgId) in info {
            for lib in pkgInfo.libraries {
                clauses.append("""
                    .product(name: "\(lib)", package: "\(pkgId.id)")
                    """)
            }
        }
        return clauses.joined(separator: ",\n")
    }
}

extension PackageGenerator {
    struct Platforms: Equatable {
        var iOS: Manifest.Platform?
        var macOS: Manifest.Platform?
        var macCatalyst: Manifest.Platform?
        var tvOS: Manifest.Platform?
        var watchOS: Manifest.Platform?

        init(iOS: Manifest.Platform? = nil,
             macOS: Manifest.Platform? = nil,
             macCatalyst: Manifest.Platform? = nil,
             tvOS: Manifest.Platform? = nil,
             watchOS: Manifest.Platform? = nil) {
            self.iOS = iOS
            self.macOS = macOS
            self.macCatalyst = macCatalyst
            self.tvOS = tvOS
            self.watchOS = watchOS
        }

        init(platforms: [Manifest.Platform]) {
            iOS = platforms.first(where: { $0.platformName == .ios })
            macOS = platforms.first(where: { $0.platformName == .macos })
            macCatalyst = platforms.first(where: { $0.platformName == .maccatalyst })
            tvOS = platforms.first(where: { $0.platformName == .tvos })
            watchOS = platforms.first(where: { $0.platformName == .watchos })
        }

        var all: [Manifest.Platform] {
            [self.iOS, self.macOS, self.macCatalyst, self.tvOS, self.watchOS].compactMap { $0 }
        }

        func merged(with other: Platforms) -> Platforms {
            .init(iOS: max(iOS, other.iOS),
                  macOS: max(macOS, other.macOS),
                  macCatalyst: max(macCatalyst, other.macCatalyst),
                  tvOS: max(tvOS, other.tvOS),
                  watchOS: max(watchOS, other.watchOS))
        }
    }

    static func mergePlatforms(_ platforms: [Platforms]) -> Platforms {
        platforms.reduce(platforms.first!) { result, next in
            result.merged(with: next)
        }
    }

    static func platformsClause(_ platforms: [Platforms]) -> String {
        platformsClause(mergePlatforms(platforms))
    }

    static func platformsClause(_ platforms: Platforms) -> String {
        guard !platforms.all.isEmpty else { return "" }
        //    .ios("13.0"),
        //    .macos("10.15"),
        //    .maccatalyst("10.15"),
        //    .tvos("13.0"),
        //    .watchos("6.0")
        let platformsList = platforms
            .all
            .map { #".\#($0.platformClauseName)("\#($0.version)")"# }
            .joined(separator: ",\n    ")
        return """
            package.platforms = [
                \(platformsList)
            ]
            """
    }

    static func content(libraries: [String]) -> String {
        """
        // Playground generated with 🏟 Arena (https://github.com/finestructure/arena)
        // ℹ️ If running the playground fails with an error "No such module"
        //    go to Product -> Build to re-trigger building the SPM package.
        // ℹ️ Please restart Xcode if autocomplete is not working.
        """ + "\n\n" +
        libraries
            // filter out any "internal" libraries (typically named with a "_" prefix)
            .filter { !$0.hasPrefix("_") }
            .map { "import \($0)" }.joined(separator: "\n") + "\n"
    }

    static func contentsXCPlayground(platform: Platform) -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <playground version='5.0' target-platform='\(platform)' buildActiveScheme='true'>
        <timeline fileName='timeline.xctimeline'/>
        </playground>
        """
    }

    static func sampleCode(path: Path) -> String? {
        let samplePath = path/".arena-sample.swift"
        if samplePath.exists {
            return try? String(contentsOf: samplePath)
        }
        return nil
    }
}


private extension Manifest.Platform {
    /// Return the name with "OS" capitalized, the way it is required in a Package.swift manifest file
    var platformClauseName: String {
        switch self.platformName {
            case .ios:
                return "iOS"
            case .maccatalyst:
                return "macCatalyst"
            case .macos:
                return "macOS"
            case .tvos:
                return "tvOS"
            case .watchos:
                return "watchOS"
        }
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
