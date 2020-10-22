public enum Progress {
    public enum Stage {
        case started
        case listPackages
        case resolvePackages
        case listLibraries
        case buildingDependencies
        case showingPlaygroundBookPath
        case showingOpenAdvisory
        case completed
    }

    public static func update(stage: Stage, description: String) { print(description) }
}
