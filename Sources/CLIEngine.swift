import Foundation
import DevBarCore

public final class CLIEngine {
    public static let shared = CLIEngine()
    private let service = DeviceService()
    private init() {}

    public func printUsage() {
        print("""
        DevBar \(DevBarVersion.current) — mobile development from your menu bar or terminal
        Usage: DevBar cli <command> [arguments] [--json]
          doctor                              Check iOS / Android tool availability
          list                                List available devices (exact IDs and names)
          boot <id-or-name>                   Boot and wait for readiness (up to 180s)
          shutdown <id-or-name>               Shut down a virtual device
          screenshot <id-or-name> [path.png]  Save a PNG (default: current directory)
          install <id-or-name> <build>        Install simulator .app / Android .apk
          launch <id-or-name> <app-id>        Launch an installed app
          open-url <id-or-name> <url>         Open a deep link
          location <id-or-name> <lat> <lon>   Set GPS on one virtual device
        Global: --help, --version. AI integration: DevBar mcp
        Android SDK: ANDROID_HOME or ANDROID_SDK_ROOT, then ~/Library/Android/sdk.
        """)
    }

    public func handle(arguments: [String]) {
        var args = Array(arguments.dropFirst(2))
        let json = args.contains("--json")
        args.removeAll { $0 == "--json" }
        if args.isEmpty || args == ["--help"] || args == ["help"] { printUsage(); return }
        do {
            let action = args.removeFirst()
            if action == "doctor" {
                guard args.isEmpty else { throw DevBarError("doctor takes no arguments.") }
                let checks = service.doctor()
                if json { try emit(checks) }
                else { checks.forEach { print("\(($0["available"] as? Bool == true) ? "OK" : "MISSING")  \($0["name"]!) — \($0["detail"]!)") } }
                // Each platform is optional, but at least one must be usable.
                if !checks.contains(where: { $0["available"] as? Bool == true && $0["name"] as? String != "Android bridge" }) { exit(1) }
                return
            }
            if action == "list" {
                guard args.isEmpty else { throw DevBarError("list takes no arguments.") }
                let devices = service.devices()
                if json { let data = try JSONEncoder().encode(devices); print(String(decoding: data, as: UTF8.self)) }
                else if devices.isEmpty { print("No devices found. Run DevBar cli doctor for setup diagnostics.") }
                else { devices.forEach { print("[\($0.platform.rawValue)] \($0.name) | \($0.state.rawValue) | \($0.id)") } }
                return
            }
            let counts = ["boot": 1...1, "shutdown": 1...1, "screenshot": 1...2, "install": 2...2, "launch": 2...2, "open-url": 2...2, "location": 3...3]
            guard let count = counts[action], count.contains(args.count) else { throw DevBarError("Unknown command or incorrect arguments. Run DevBar cli --help.") }
            // Validate input before scanning or touching devices.
            if action == "location" {
                guard let lat = Double(args[1]), let lon = Double(args[2]) else { throw DevBarError("GPS coordinates must be numbers.") }
                try DeviceService.validateLocation(lat, lon)
            }
            let device = try DeviceService.resolve(args[0], in: service.devices())
            var result: [String: Any] = ["success": true, "command": action, "device": device.id]
            switch action {
            case "boot": try service.boot(device)
            case "shutdown": try service.shutdown(device)
            case "screenshot": result["path"] = try service.screenshot(device, path: args.count == 2 ? args[1] : "DevBar-\(UUID().uuidString).png")
            case "install": try service.install(device, path: args[1])
            case "launch": try service.launch(device, app: args[1])
            case "open-url": try service.openURL(device, url: args[1])
            case "location": try service.location(device, latitude: Double(args[1])!, longitude: Double(args[2])!)
            default: break
            }
            if json { try emit(result) }
            else { print("\(action) completed for \(device.name).\(result["path"].map { " Saved: \($0)" } ?? "")") }
        } catch {
            if json { try? emit(["success": false, "error": error.localizedDescription]) }
            else { FileHandle.standardError.write(Data("Error: \(error.localizedDescription)\n".utf8)) }
            exit(1)
        }
    }

    private func emit(_ value: Any) throws {
        let data = try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
        print(String(decoding: data, as: UTF8.self))
    }
}
