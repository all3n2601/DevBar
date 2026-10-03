import Cocoa
import DevBarCore

autoreleasepool {
    let arguments = CommandLine.arguments
    #if DEBUG
    if arguments.dropFirst().first == "--capture-docs", arguments.count == 3 {
        do { try DocumentationCapture.run(directory: arguments[2]) }
        catch { FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8)); exit(1) }
        exit(0)
    }
    #endif
    switch arguments.dropFirst().first {
    case "cli": CLIEngine.shared.handle(arguments: arguments)
    case "mcp": MCPEngine.shared.start()
    case "--version": print(DevBarVersion.current)
    case "--help", "-h": CLIEngine.shared.printUsage()
    case nil:
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    default:
        FileHandle.standardError.write(Data("Use DevBar --help, cli, or mcp.\n".utf8))
        exit(2)
    }
}
