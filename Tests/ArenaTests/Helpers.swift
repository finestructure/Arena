import SemanticVersion


extension SemanticVersion: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = SemanticVersion(value)!
    }
}
