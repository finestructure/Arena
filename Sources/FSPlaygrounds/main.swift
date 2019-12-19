import Foundation
import Path
import ShellOut
import Yaap


enum Platform: String {
    case ios
    case macos
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
    var name = ""

    let projectName = "myproj"

    @Option(name: "url", shorthand: "u", documentation: "package url")
    var pkgURL: String? = nil

    @Option(name: "from", shorthand: "f", documentation: "from revision")
    var pkgFrom: String = "0.0.0"

    let libName = "Plot"
    let platform: Platform = .macos

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

extension SPMPlaygroundCommand: Command {
    func run(outputStream: inout TextOutputStream, errorStream: inout TextOutputStream) throws {
        guard let url = pkgURL else {
            print("<url> parameter required")
            exit(1)
        }

        guard URL(string: url) != nil else {
            print("invalid url: '\(url)'")
            exit(1)
        }

        if force && projectPath().exists {
            try projectPath().delete()
        }
        guard !projectPath().exists else {
            print("'\(projectPath().basename())' already exists")
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

        try shellOut(to: .openFile(at: projectPath()))
    }
}

SPMPlaygroundCommand().parseAndRun()
