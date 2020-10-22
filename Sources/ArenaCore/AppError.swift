import Foundation


public enum AppError: LocalizedError {
    case invalidPath(String)
    case missingDependency
    case pathExists(String)
    case noLibrariesFound
    case noSourcesFound

    public var errorDescription: String? {
        switch self {
            case .invalidPath(let path):
                return "'\(path)' is not a valid path"
            case .missingDependency:
                return "provide at least one dependency"
            case .pathExists(let path):
                return "'\(path)' already exists, use '-f' to overwrite"
            case .noLibrariesFound:
                return "no libraries found, make sure the referenced dependencies define library products"
            case .noSourcesFound:
                return "no source files found, make sure the referenced dependencies contain swift files in their 'Sources' folders"
        }
    }
}
