import Foundation
import Path
import ShellOut
import Yaap


enum Platform: String {
    case ios
    case macos
    case tvos
}


extension Platform: CustomStringConvertible {
    var description: String {
        switch self {
            case .ios: return "ios"
            case .macos: return "macos"
            case .tvos: return "tvos"
        }
    }
}


extension Platform: ArgumentType {
    init(arguments: inout [String]) throws {
        guard let argument = arguments.first else {
            throw ParseError.missingArgument
        }

        guard let value = Platform.init(rawValue: argument) else {
            throw ParseError.invalidFormat(argument)
        }

        self = value
        arguments.removeFirst()
    }
}


@discardableResult
func shellOut(to command: ShellOutCommand, at path: Path) throws -> String {
    try shellOut(to: command, at: "\(path)", outputHandle: nil, errorHandle: nil)
}


extension ShellOutCommand {
    static func openFile(at path: Path) -> ShellOutCommand {
        return ShellOutCommand(string: "open \(path)")
    }
}


extension Optional: CustomStringConvertible where Wrapped == String {
    public var description: String {
        switch self {
            case let .some(value): return value
            case .none: return "nil"
        }
    }

}


extension Optional: ArgumentType where Wrapped == String {
    public init(arguments: inout [String]) throws {
        self = arguments.first
        if !arguments.isEmpty {
            arguments.removeFirst()
        }
    }
}


class SPMPlaygroundCommand {
    let name = "spm-playground"
    let documentation = "Creates an Xcode project with a Playground and an SPM library ready for use in it."
    let help = Help()

    @Option(name: "name", shorthand: "n", documentation: "name of directory and Xcode project")
    var projectName = "SPM-Playground"

    @Option(name: "url", shorthand: "u", documentation: "package url")
    var pkgURL: String? = nil

    @Option(name: "from", shorthand: "f", documentation: "from revision")
    var pkgFrom: String = "0.0.0"

    @Option(name: "library", shorthand: "l", documentation: "name of library to import (inferred if not provided)")
    var _libName: String? = nil

    @Option(shorthand: "p", documentation: "platform for Playground (one of 'macos', 'ios', 'tvos')")
    var platform: Platform = .macos

    let version = Version(SPMPlaygroundVersion)

    @Option(documentation: "overwrite existing file/directory")
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
}


func inferLibName(from url: URL) -> String {
    // avoid using deletingPathExtension().lastPathComponent because there are cases like
    // https://github.com/mxcl/Path.swift.git
    let inferred = url.lastPathComponent.split(separator: ".").first.map(String.init) ?? url.lastPathComponent
    print("ℹ️  inferred library name '\(inferred)' from url '\(url)'")
    return inferred
}


extension SPMPlaygroundCommand: Command {
    func run(outputStream: inout TextOutputStream, errorStream: inout TextOutputStream) throws {
        guard let urlString = pkgURL else {
            print("❌  <url> parameter required")
            exit(1)
        }

        guard let url = URL(string: urlString) else {
            print("❌  invalid url: '\(urlString)'")
            exit(1)
        }

        let libName = _libName ?? inferLibName(from: url)

        if force && projectPath().exists {
            try projectPath().delete()
        }
        guard !projectPath().exists else {
            print("❌  '\(projectPath().basename())' already exists, use '--force' to overwrite")
            exit(1)
        }
        try projectPath().mkdir()

        // create package
        try shellOut(to: .createSwiftPackage(withType: .library), at: projectPath())

        // update Package.swift
        do {
            let packagePath = projectPath()/"Package.swift"
            let packageDescription = try String(contentsOf: packagePath)
            let updatedDeps = "package.dependencies = [.package(url: \"\(url)\", from: \"\(pkgFrom)\")]"
            let updatedTgts =  "package.targets = [.target(name: \"\(targetName)\", dependencies: [\"\(libName)\"])]"
            try [packageDescription, updatedDeps, updatedTgts].joined(separator: "\n").write(to: packagePath)
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
            try "import \(libName)\n\n".write(to: playgroundPath()/"Contents.swift")
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

SPMPlaygroundCommand().parseAndRun()
