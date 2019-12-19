import Commander
import Foundation
import Path
import ShellOut


enum Platform: String {
    case ios
    case macos
}


struct Config {
    let projectName = "myproj"
    let pkgURL: String
    let pkgFrom: String
    let libName = "Plot"
    let platform: Platform = .macos

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


@discardableResult
func shellOut(to command: ShellOutCommand, at path: Path) throws -> String {
    try shellOut(to: command, at: "\(path)", outputHandle: nil, errorHandle: nil)
}


extension ShellOutCommand {
    static func openFile(at path: Path) -> ShellOutCommand {
        return ShellOutCommand(string: "open \(path)")
    }
}



let app = command(
    Flag("force", default: false, description: "overwrite existing file/directory"),
    Option<String>("url", default: "", flag: "u", description: "repository url"),
    Option<String>("from", default: "0.0.0", flag: "f", description: "from revision")
) { force, url, from in

    guard URL(string: url) != nil else {
        print("invalid url: '\(url)'")
        exit(1)
    }

    let config = Config.init(
        pkgURL: url,
        pkgFrom: from
    )

    if force && config.projectPath().exists {
        try config.projectPath().delete()
    }
    guard !config.projectPath().exists else {
        print("'\(config.projectPath().basename())' already exists")
        exit(1)
    }
    try config.projectPath().mkdir()

    // create package
    try shellOut(to: .createSwiftPackage(withType: .library), at: config.projectPath())

    // update Package.swift
    do {
        let packagePath = config.projectPath()/"Package.swift"
        let packageDescription = try String(contentsOf: packagePath)
        let updatedDeps = "package.dependencies = [.package(url: \"\(config.pkgURL)\", from: \"\(config.pkgFrom)\")]"
        let updatedTgts =  "package.targets = [.target(name: \"\(config.targetName)\", dependencies: [\"\(config.libName)\"])]"

        try [packageDescription, updatedDeps, updatedTgts].joined(separator: "\n").write(to: packagePath)
    }

    // generate xcodeproj
    try shellOut(to: .generateSwiftPackageXcodeProject(), at: config.projectPath())

    // create workspace
    do {
        try config.xcworkspacePath().mkdir()
        try """
            <?xml version="1.0" encoding="UTF-8"?>
            <Workspace
               version = "1.0">
               <FileRef
                  location = "group:MyPlayground.playground">
               </FileRef>
               <FileRef
                  location = "container:\(config.xcodeprojPath().basename())">
               </FileRef>
            </Workspace>
            """.write(to: config.xcworkspacePath()/"contents.xcworkspacedata")
    }

    // add playground
    do {
        try config.playgroundPath().mkdir()
        try "import \(config.libName)\n\n".write(to: config.playgroundPath()/"Contents.swift")
        try """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <playground version='5.0' target-platform='\(config.platform)'>
                <timeline fileName='timeline.xctimeline'/>
            </playground>
            """.write(to: config.playgroundPath()/"contents.xcplayground")
    }

    print("open \(config.xcworkspacePath())")
    //    try shellOut(to: .openFile(at: config.xcworkspacePath()))
}

app.run()
