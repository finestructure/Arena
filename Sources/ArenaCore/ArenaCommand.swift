import ArgumentParser
import Foundation
import Path
import ShellOut


public struct Arena: ParsableCommand {
    static let playgroundName = "Arena-Playground"

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
    var outputPath: Path = Path.cwd/playgroundName

    @Option(name: .shortAndLong,
            help: "Platform for Playground (one of 'macos', 'ios', 'tvos')")
    var platform: Platform = .macos

    @Flag(name: [.customLong("version"), .customShort("v")],
          help: "Show version")
    var showVersion: Bool = false

    @Flag(name: .long, help: "Do not open project in Xcode on completion")
    var skipOpen: Bool = false

    @Argument(help: "Dependency url(s) and (optionally) version specification")
    var dependencies: [Dependency] = []

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
            throw AppError.invalidPath(outputPath)
        }

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
    var dependencyPackagePath: Path { outputPath/depdencyPackageName }

    var depdencyPackageName: String { "Dependencies" }

    var xcworkspacePath: Path {
        outputPath/"Arena.xcworkspace"
    }

    var playgroundPath: Path {
        outputPath/"MyPlayground.playground"
    }
}


extension Arena {
    public func run() throws {
        try run(progress: Progress.update)
    }

    public func run(progress: (Progress.Stage, String) -> ()) throws {
        if showVersion {
            progress(.started, ArenaVersion)
            return
        }

        guard !dependencies.isEmpty else {
            throw AppError.missingDependency
        }

        if force && outputPath.exists {
            try outputPath.delete()
        }
        guard !outputPath.exists else {
            throw AppError.pathExists(outputPath.basename())
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
                        $0.path ?? $0.checkoutDir(packageDir: dependencyPackagePath)
                    }.compactMap { try getPackageInfo(in: $0) } )
            )
            let libs = packageInfo.flatMap { $0.1.libraries }
            if libs.isEmpty { throw AppError.noLibrariesFound }
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
            try [packageDescription,
                 PackageGenerator.platformsClause(platforms)]
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
                location = "group:\(depdencyPackageName)">
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
                .compactMap { $0.path ?? $0.checkoutDir(packageDir: dependencyPackagePath) }
                .compactMap(Module.init)
            if modules.isEmpty { throw AppError.noSourcesFound }
            try PlaygroundBook.make(named: Self.playgroundName, in: outputPath, with: modules)
            progress(.showingPlaygroundBookPath,
                     "📙 Created Playground Book in folder '\(outputPath.relative(to: Path.cwd))'")
        }

        progress(.completed, "✅ Created project in folder '\(outputPath.relative(to: Path.cwd))'")
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

