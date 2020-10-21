struct PlatformVersion {
    var major: Int
    var minor: Int

    init?(string: String) {
        let parts = string.split(separator: ".")
            .map(String.init)
            .compactMap(Int.init)
        guard parts.count == 2 else { return nil }
        major = parts[0]
        minor = parts[1]
    }
}


extension PlatformVersion: Comparable {
    static func < (lhs: PlatformVersion, rhs: PlatformVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        return lhs.minor < rhs.minor
    }
}
