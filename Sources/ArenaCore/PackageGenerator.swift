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
