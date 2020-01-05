import Foundation
import SPMPlayground


internal class FileOutputStream: TextOutputStream {
    private let handle: FileHandle

    internal init(handle: FileHandle) {
        self.handle = handle
    }

    internal func write(_ string: String) {
        handle.write(string.data(using: .utf8)!)
    }
}


do {
    let cmd = SPMPlaygroundCommand()
    var arguments = Array(CommandLine.arguments.dropFirst())
    try cmd.parse(arguments: &arguments)
    var out: TextOutputStream = FileOutputStream(handle: .standardOutput)
    var err: TextOutputStream = FileOutputStream(handle: .standardError)
    try cmd.run(outputStream: &out, errorStream: &err)
} catch let e as SPMPlaygroundError {
    print(e.localizedDescription)
} catch {
    print("error: \(error)")
}
