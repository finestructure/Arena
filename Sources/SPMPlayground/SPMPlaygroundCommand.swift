//
//  SPMPlaygroundCommand.swift
//  
//
//  Created by Sven A. Schmidt on 23/12/2019.
//

import Foundation
import Path
import ShellOut
import Yaap


public enum SPMPlaygroundError: LocalizedError {
    case missingDependency
    case pathExists(String)

    public var errorDescription: String? {
        switch self {
            case .missingDependency:
                return "no dependency provided via -d parameter"
            case .pathExists(let path):
                return "'\(path)' already exists"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
            case .missingDependency:
                return "provide at least one <dependency>"
            case .pathExists:
                return "use '--force' to overwrite"
        }
    }

    public var localizedDescription: String {
        "❌  \(errorDescription!), \(recoverySuggestion!)"
    }
}


public class SPMPlaygroundCommand {
    public let name = "spm-playground"
    public let documentation = "Creates an Xcode project with a Playground and an SPM library ready for use in it."
    let help = Help()

    @Option(name: "name", shorthand: "n", documentation: "name of directory and Xcode project")
    var projectName = "SPM-Playground"

    @Option(name: "deps", shorthand: "d", documentation: "dependency url(s) and (optionally) version specification")
    var dependencies = [Dependency]()

    // TODO: turn into array
    @Option(name: "library", shorthand: "l", documentation: "name of library to import (inferred if not provided)")
    var libName: String? = nil

    @Option(shorthand: "p", documentation: "platform for Playground (one of 'macos', 'ios', 'tvos')")
    var platform: Platform = .macos

    let version = Version(SPMPlaygroundVersion)

    @Option(shorthand: "f", documentation: "overwrite existing file/directory")
    var force = false

    @Option(name: "outputdir", shorthand: "o", documentation: "directory where project folder should be saved")
    var outputPath = Path.cwd

    var targetName: String { projectName }

    var projectPath: Path { outputPath/projectName }

    func xcodeprojPath(parentDir: Path = Path.cwd) -> Path {
        projectPath/"\(projectName).xcodeproj"
    }

    func xcworkspacePath(parentDir: Path = Path.cwd) -> Path {
        projectPath/"\(projectName).xcworkspace"
    }

    func playgroundPath(parentDir: Path = Path.cwd) -> Path {
        projectPath/"MyPlayground.playground"
    }

    public init() {}
}


extension SPMPlaygroundCommand: Command {
    public func run(outputStream: inout TextOutputStream, errorStream: inout TextOutputStream) throws {
        guard !dependencies.isEmpty else {
            throw SPMPlaygroundError.missingDependency
        }

        if force && projectPath.exists {
            try projectPath.delete()
        }
        guard !projectPath.exists else {
            throw SPMPlaygroundError.pathExists(projectPath.basename())
        }

        // create package
        do {
            try projectPath.mkdir()
            let swift = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift"
            try shellOut(to: ShellOutCommand(string: "\(swift)-package init --type library"), at: projectPath)
        }

        // update Package.swift dependencies
        do {
            let packagePath = projectPath/"Package.swift"
            let packageDescription = try String(contentsOf: packagePath)
            let depsClause = dependencies.map { "    " + $0.packageClause }.joined(separator: ",\n")
            let updatedDeps = "package.dependencies = [\n\(depsClause)\n]"
            try [packageDescription, updatedDeps].joined(separator: "\n").write(to: packagePath)
        }

        do {
            print("🔧  resolving package dependencies")
            let swift = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift"
            try shellOut(to: ShellOutCommand(string: "\(swift)-package resolve"), at: projectPath)
        }

        let libs: [String]
        do {
            // find libraries
            libs = try dependencies
                .compactMap { $0.path ?? $0.checkoutDir(projectDir: projectPath) }
                .flatMap { try libraryNames(for: $0) }
            assert(libs.count > 0, "❌  no libraries found!")
            print("📔  libraries found: \(libs.joined(separator: ", "))")
        }

        // update Package.swift targets
        do {
            let packagePath = projectPath/"Package.swift"
            let packageDescription = try String(contentsOf: packagePath)
            let libsClause = libs.map { "\"\($0)\"" }.joined(separator: ", ")
            let updatedTgts =  "package.targets = [.target(name: \"\(targetName)\", dependencies: [\(libsClause)])]"
            try [packageDescription, updatedTgts].joined(separator: "\n").write(to: packagePath)
        }

        // generate xcodeproj
        let swift = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift"
        try shellOut(to: ShellOutCommand(string: "\(swift)-package generate-xcodeproj"), at: projectPath)

        // create workspace
        do {
            try xcworkspacePath().mkdir()
            try """
                <?xml version="1.0" encoding="UTF-8"?>
                <Workspace
                version = "1.0">
                <FileRef
                location = "group:MyPlayground.playground">
                </FileRef>
                <FileRef
                location = "container:\(xcodeprojPath().basename())">
                </FileRef>
                </Workspace>
                """.write(to: xcworkspacePath()/"contents.xcworkspacedata")
        }

        // add playground
        do {
            try playgroundPath().mkdir()
            let importClauses = (libName.map { [$0] } ?? libs).map { "import \($0)" }.joined(separator: "\n") + "\n"
            try importClauses.write(to: playgroundPath()/"Contents.swift")
            try """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <playground version='5.0' target-platform='\(platform)'>
                <timeline fileName='timeline.xctimeline'/>
                </playground>
                """.write(to: playgroundPath()/"contents.xcplayground")
        }

        print("✅  created project in folder '\(projectPath.relative(to: Path.cwd))'")
        try shellOut(to: .openFile(at: projectPath))
    }
}

