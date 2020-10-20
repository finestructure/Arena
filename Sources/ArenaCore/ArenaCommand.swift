//
//  ArenaCommand.swift
//  
//
//  Created by Sven A. Schmidt on 23/12/2019.
//

import ArgumentParser
import Foundation
import Path
import ShellOut


public enum ArenaError: LocalizedError {
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


public struct Arena: ParsableCommand {
    public static var configuration = CommandConfiguration(
        abstract: "Creates an Xcode project with a Playground and one or more SPM libraries imported and ready for use."
    )

    @Flag(name: .long, help: "Create a Swift Playgrounds compatible Playground Book bundle (experimental).")
    var book: Bool = false
    
    @Flag(name: .shortAndLong,
          help: "Overwrite existing file/directory")
    var force: Bool = false

    @Option(name: [.customLong("libs"), .customShort("l")],
            parsing: .upToNextOption,
            help: "Names of libraries to import (inferred if not provided)")
    var libNames: [String] = []

    @Option(name: [.customLong("outputdir"), .customShort("o")],
            help: "Directory where project folder should be saved")
    var outputPath: Path = try! Path.cwd.realpath()

    @Option(name: .shortAndLong,
            help: "Platform for Playground (one of 'macos', 'ios', 'tvos')")
    var platform: Platform = .macos

    @Option(name: [.customLong("name"), .customShort("n")],
            help: "Name of directory and Xcode project")
    var projectName: String = "Arena-Playground"

    @Flag(name: [.customLong("version"), .customShort("v")],
          help: "Show version")
    var showVersion: Bool = false

    @Flag(name: .long, help: "Do not open project in Xcode on completion")
    var skipOpen: Bool = false

    @Argument(help: "Dependency url(s) and (optionally) version specification")
    var dependencies: [Dependency]

    public init() {}
}


extension Arena {
    public init(projectName: String,
                libNames: [String],
                platform: Platform,
                force: Bool,
                outputPath: String,
                skipOpen: Bool,
                book: Bool,
                dependencies: [Dependency]) throws {

        guard let path = Path(outputPath) else {
            throw ArenaError.invalidPath(outputPath)
        }

        self.projectName = projectName
        self.libNames = libNames
        self.platform = platform
        self.force = force
        self.outputPath = path
        self.showVersion = false
        self.skipOpen = skipOpen
        self.book = book
        self.dependencies = dependencies
    }
}


extension Arena {
    var dependencyPackagePath: Path { projectPath/depdencyPackageName }

    var depdencyPackageName: String { "Dependencies" }

    var projectPath: Path { outputPath/projectName }

    var xcworkspacePath: Path {
        projectPath/"Arena.xcworkspace"
    }

    var playgroundPath: Path {
        projectPath/"MyPlayground.playground"
    }
}


public typealias ProgressUpdate = (Progress.Stage, String) -> ()


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


extension Arena {
    public func run() throws {
        try run(progress: Progress.update)
    }

    public func run(progress: ProgressUpdate) throws {
        if showVersion {
            progress(.started, ArenaVersion)
            return
        }

        guard !dependencies.isEmpty else {
            throw ArenaError.missingDependency
        }

        if force && projectPath.exists {
            try projectPath.delete()
        }
        guard !projectPath.exists else {
            throw ArenaError.pathExists(projectPath.basename())
        }

        dependencies.forEach {
            progress(.listPackages, "➡️  Package: \($0)")
        }

        // create package
        do {
            try dependencyPackagePath.mkdir(.p)
            try shellOut(to: .createSwiftPackage(withType: .library), at: dependencyPackagePath)
        }

        // update Package.swift dependencies
        // we need to keep the original description around, because we're going to re-write
        // the manifest a second time, after we've resolved the packages. This is because we
        // the manifest to resolve the packages and we need package resolution to be able to
        // get PackageInfo, which we'll need to write out the proper dependency incl `name:`
        // See https://github.com/finestructure/Arena/issues/33
        // and https://github.com/finestructure/Arena/issues/38
        let packagePath = dependencyPackagePath/"Package.swift"
        let originalPackageDescription = try String(contentsOf: packagePath)
        do {
            let depsClause = dependencies.map { "    " + $0.packageClause() }.joined(separator: ",\n")
            let updatedDeps = "package.dependencies = [\n\(depsClause)\n]"
            try [originalPackageDescription, updatedDeps].joined(separator: "\n").write(to: packagePath)
        }

        do {
            progress(.resolvePackages, "🔧 Resolving package dependencies ...")
            try shellOut(to: ShellOutCommand(string: "swift package resolve"), at: dependencyPackagePath)
        }

        let packageInfo: [(Dependency, PackageInfo)]
        do {
            // find libraries
            packageInfo = Array(
                zip(dependencies,
                    try dependencies.compactMap {
                        $0.path ?? $0.checkoutDir(projectDir: dependencyPackagePath)
                    }.compactMap { try getPackageInfo(in: $0) } )
            )
            let libs = packageInfo.flatMap { $0.1.libraries }
            if libs.isEmpty { throw ArenaError.noLibrariesFound }
            progress(.listLibraries, "📔 Libraries found: \(libs.joined(separator: ", "))")
        }

        // update Package.swift dependencies again, adding in package `name:` and
        // the `platforms` stanza (if required)
        do {
            let depsClause = packageInfo.map { (dep, pkg) in
                "    " + dep.packageClause(name: pkg.name)
            }.joined(separator: ",\n")
            let updatedDeps = "package.dependencies = [\n\(depsClause)\n]"
            try [originalPackageDescription, updatedDeps].joined(separator: "\n").write(to: packagePath)
        }

        // update Package.swift targets
        do {
            let packagePath = dependencyPackagePath/"Package.swift"
            let packageDescription = try String(contentsOf: packagePath)
            let updatedTgts =  """
                package.targets = [
                    .target(name: "\(depdencyPackageName)",
                        dependencies: [
                            \(PackageGenerator.productsClause(packageInfo))
                        ]
                    )
                ]
                """
            try [packageDescription, updatedTgts].joined(separator: "\n").write(to: packagePath)
        }

        // update Package.swift platforms
        do {
            let packagePath = dependencyPackagePath/"Package.swift"
            let packageDescription = try String(contentsOf: packagePath)
            let platforms = packageInfo.compactMap {
                $0.1.platforms
                    .map(PackageGenerator.Platforms.init(platforms:))
            }
            let platformsClause = """
                package.platforms = [
                    \(PackageGenerator.platformsClause(platforms, indentation: "    "))
                ]
                """
            try [packageDescription, platformsClause]
                .joined(separator: "\n").write(to: packagePath)
        }

        // create workspace
        do {
            try xcworkspacePath.mkdir()
            try """
                <?xml version="1.0" encoding="UTF-8"?>
                <Workspace
                version = "1.0">
                <FileRef
                location = "group:MyPlayground.playground">
                </FileRef>
                <FileRef
                location = "group:Dependencies">
                </FileRef>
                </Workspace>
                """.write(to: xcworkspacePath/"contents.xcworkspacedata")
        }

        // add playground
        do {
            try playgroundPath.mkdir()
            let libsToImport = !libNames.isEmpty ? libNames : packageInfo.flatMap { $0.1.libraries }
            let importClauses =
                """
                // Playground generated with 🏟 Arena (https://github.com/finestructure/arena)
                // ℹ️ If running the playground fails with an error "no such module ..."
                //    go to Product -> Build to re-trigger building the SPM package.
                // ℹ️ Please restart Xcode if autocomplete is not working.
                """ + "\n\n" +
                libsToImport.map { "import \($0)" }.joined(separator: "\n") + "\n"
            try importClauses.write(to: playgroundPath/"Contents.swift")
            try """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <playground version='5.0' target-platform='\(platform)' buildActiveScheme='true'>
                <timeline fileName='timeline.xctimeline'/>
                </playground>
                """.write(to: playgroundPath/"contents.xcplayground")
        }

        if book {
            let modules = dependencies
                .compactMap { $0.path ?? $0.checkoutDir(projectDir: projectPath) }
                .compactMap(Module.init)
            if modules.isEmpty { throw ArenaError.noSourcesFound }
            try PlaygroundBook.make(named: projectName, in: projectPath, with: modules)
            progress(.showingPlaygroundBookPath,
                     "📙 Created Playground Book in folder '\(projectPath.relative(to: Path.cwd))'")
        }

        progress(.completed, "✅ Created project in folder '\(projectPath.relative(to: Path.cwd))'")
        if skipOpen {
            progress(.showingOpenAdvisory, """
                Run
                  open \(xcworkspacePath.relative(to: Path.cwd))
                to open the project in Xcode
                """
            )
        } else {
            try shellOut(to: .openFile(at: xcworkspacePath))
        }
    }
}

