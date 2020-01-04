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

    var targetName: String { projectName }

    func projectPath(at parentDir: Path = Path.cwd) -> Path {
        parentDir.join(projectName)
    }

    func xcodeprojPath(parentDir: Path = Path.cwd) -> Path {
        projectPath(at: parentDir)/"\(projectName).xcodeproj"
    }

    func xcworkspacePath(parentDir: Path = Path.cwd) -> Path {
        projectPath(at: parentDir)/"\(projectName).xcworkspace"
    }

    func playgroundPath(parentDir: Path = Path.cwd) -> Path {
        projectPath(at: parentDir)/"MyPlayground.playground"
    }

    public init() {}
}


extension SPMPlaygroundCommand: Command {
    public func run(outputStream: inout TextOutputStream, errorStream: inout TextOutputStream) throws {
        guard !dependencies.isEmpty else {
            print("❌  provide at least one <dependency>")
            exit(EXIT_FAILURE)
        }

        if force && projectPath().exists {
            try projectPath().delete()
        }
        guard !projectPath().exists else {
            print("❌  '\(projectPath().basename())' already exists, use '--force' to overwrite")
            exit(1)
        }

        // create package
        do {
            try projectPath().mkdir()
            try shellOut(to: .createSwiftPackage(withType: .library), at: projectPath())
        }

        // update Package.swift dependencies
        do {
            let packagePath = projectPath()/"Package.swift"
            let packageDescription = try String(contentsOf: packagePath)
            let depsClause = dependencies.map { "    " + $0.packageClause }.joined(separator: ",\n")
            let updatedDeps = "package.dependencies = [\n\(depsClause)\n]"
            try [packageDescription, updatedDeps].joined(separator: "\n").write(to: packagePath)
        }

        do {
            print("🔧  resolving package dependencies")
            try shellOut(to: ShellOutCommand(string: "swift package resolve"), at: projectPath())
        }

        let libs: [String]
        do {
            // find libraries
            libs = try dependencies
                .compactMap { $0.path ?? $0.checkoutDir(projectDir: projectPath()) }
                .flatMap { try libraryNames(for: $0) }
            assert(libs.count > 0, "❌  no libraries found!")
            print("📔  libraries found: \(libs.joined(separator: ", "))")
        }

        // update Package.swift targets
        do {
            let packagePath = projectPath()/"Package.swift"
            let packageDescription = try String(contentsOf: packagePath)
            let libsClause = libs.map { "\"\($0)\"" }.joined(separator: ", ")
            let updatedTgts =  "package.targets = [.target(name: \"\(targetName)\", dependencies: [\(libsClause)])]"
            try [packageDescription, updatedTgts].joined(separator: "\n").write(to: packagePath)
        }

        // generate xcodeproj
        try shellOut(to: .generateSwiftPackageXcodeProject(), at: projectPath())

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

        print("✅  created project in folder '\(projectPath().relative(to: Path.cwd))'")
        try shellOut(to: .openFile(at: projectPath()))
    }
}

