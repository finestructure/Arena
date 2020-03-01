//
//  PlaygroundBook.swift
//  
//
//  Created by Sven A. Schmidt on 01/03/2020.
//

import Path


public struct Module {
    var name: String
    var sources: [Path]

    init?(path: Path) {
        let sourceDir = path.join("Sources")
        guard sourceDir.exists else { return nil }
        self.name = path.basename()
        self.sources = sourceDir.find().extension("swift").type(.file).map { $0 }
    }
}


public enum PlaygroundBook {
    public static func make(named name: String, in parent: Path, with modules: [Module]) throws {
        let book = try parent.join("\(name).playgroundbook").mkdir()
        try mkContents(parent: book, modules: modules)
    }
}


private extension PlaygroundBook {

    static let chapter1Manifest = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Name</key>
            <string>My Playground</string>
            <key>TemplatePageFilename</key>
            <string>Template.playgroundpage</string>
            <key>InitialUserPages</key>
            <array>
                <string>My Playground.playgroundpage</string>
            </array>
        </dict>
        </plist>
        """

    static let contentsManifest = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Chapters</key>
            <array>
                <string>Chapter1.playgroundchapter</string>
            </array>
            <key>ContentIdentifier</key>
            <string>com.apple.playgrounds.blank</string>
            <key>ContentVersion</key>
            <string>1.0</string>
            <key>DeploymentTarget</key>
            <string>ios-current</string>
            <key>DevelopmentRegion</key>
            <string>en</string>
            <key>SwiftVersion</key>
            <string>5.1</string>
            <key>Version</key>
            <string>7.0</string>
            <key>UserAutoImportedAuxiliaryModules</key>
            <array/>
            <key>UserModuleMode</key>
            <string>Full</string>
        </dict>
        </plist>
        """

    static func myPlaygroundPageManifest(named name: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Name</key>
            <string>\(name)</string>
            <key>LiveViewEdgeToEdge</key>
            <false/>
            <key>LiveViewMode</key>
            <string>HiddenByDefault</string>
        </dict>
        </plist>
        """
    }

    static let mainSwift = """
        // ℹ️ The source files of your dependencies have been copied into the
        //    UserModule/Sources folder and their public interfaces are
        //    available without requiring a module import.
        """

    static func mkContents(parent: Path, modules: [Module]) throws {
        let contents = try parent.join("Contents").mkdir()
        try contentsManifest.write(to: contents/"Manifest.plist")
        try mkChapters(in: contents)
        try mkUserModules(in: contents, modules: modules)
    }

    static func mkChapters(in parent: Path) throws {
        let chapters = try parent.join("Chapters").mkdir()
        let chapter1 = try chapters.join("Chapter1.playgroundchapter").mkdir()
        try chapter1Manifest.write(to: chapter1/"Manifest.plist")
        let pages = try chapter1.join("Pages").mkdir()
        try mkPlaygroundPage(in: pages, named: "My Playground")
        try mkPlaygroundPage(in: pages, named: "Template")
    }

    static func mkPlaygroundPage(in parent: Path, named name: String) throws {
        let page = try parent.join("\(name).playgroundpage").mkdir()
        try myPlaygroundPageManifest(named: name).write(to: page/"Manifest.plist")
        try mainSwift.write(to: page/"main.swift")
    }

    static func mkUserModules(in parent: Path, modules: [Module]) throws {
        let sources = try parent.join("UserModules/UserModule.playgroundmodule/Sources").mkdir(.p)
        for module in modules {
            for src in module.sources {
                let target = sources.join(module.name + "-" + src.basename())
                try src.copy(to: target, overwrite: false)
            }
        }
    }

}
