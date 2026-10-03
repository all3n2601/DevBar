import Foundation

public struct DevBarError: LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

extension DeviceService {
    @discardableResult
    public func checked(_ executable: String, _ arguments: [String], timeout: TimeInterval = 30) throws -> String {
        let result = runner(executable, arguments, timeout)
        guard result.status == 0 else {
            throw DevBarError(result.error.isEmpty ? "Command failed (\(result.status)): \(result.output)" : result.error)
        }
        return result.output
    }

    public static func resolve(_ identifier: String, in devices: [Device]) throws -> Device {
        if let device = devices.first(where: { $0.id == identifier }) { return device }
        let matches = devices.filter { $0.name == identifier }
        guard matches.count == 1 else {
            throw DevBarError(matches.isEmpty ? "Device '\(identifier)' not found. Run cli list." : "Multiple devices named '\(identifier)'. Use an exact ID.")
        }
        return matches[0]
    }

    public static func validateLocation(_ latitude: Double, _ longitude: Double) throws {
        guard latitude.isFinite, longitude.isFinite, (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw DevBarError("Latitude must be -90…90 and longitude -180…180.")
        }
    }

    // adb shell joins its arguments before passing them to the device shell.
    public static func remoteQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func requireRunning(_ device: Device) throws {
        guard device.state == .booted else { throw DevBarError("Boot \(device.name) first.") }
    }

    public func boot(_ device: Device) throws {
        if device.state == .booted { return }
        guard !device.isPhysical else { throw DevBarError("Physical devices cannot be booted by DevBar.") }
        if device.platform == .ios {
            if device.state != .booting { try checked("/usr/bin/xcrun", ["simctl", "boot", device.id]) }
            try checked("/usr/bin/xcrun", ["simctl", "bootstatus", device.id, "-b"], timeout: 180)
        } else {
            guard let process = Shell.shared.runAsynchronousProcess(executable: Shell.shared.resolveEmulatorPath(), arguments: ["-avd", device.id]) else {
                throw DevBarError("Could not start Android emulator. Run cli doctor.")
            }
            let deadline = Date().addingTimeInterval(180)
            while Date() < deadline {
                if !process.isRunning { throw DevBarError("Android emulator exited before startup completed.") }
                if let active = fetchAndroidDevices().first(where: { $0.name == device.name && $0.state == .booted }) {
                    let result = Shell.shared.run(executable: Shell.shared.resolveAdbPath(), arguments: ["-s", active.id, "shell", "getprop", "sys.boot_completed"], timeout: 5)
                    if result.status == 0 && result.output == "1" { return }
                }
                Thread.sleep(forTimeInterval: 1)
            }
            throw DevBarError("Android boot did not finish within 180 seconds. Emulator remains running.")
        }
    }

    public func shutdown(_ device: Device) throws {
        guard !device.isPhysical else { throw DevBarError("Physical Android devices cannot be shut down by DevBar.") }
        if device.state == .shutdown { return }
        if device.platform == .ios { try checked("/usr/bin/xcrun", ["simctl", "shutdown", device.id]) }
        else { try checked(Shell.shared.resolveAdbPath(), ["-s", device.id, "emu", "kill"]) }
    }

    public func screenshot(_ device: Device, path: String) throws -> String {
        try requireRunning(device)
        let url = URL(fileURLWithPath: path).standardizedFileURL
        guard !FileManager.default.fileExists(atPath: url.path) else { throw DevBarError("Output already exists: \(url.path)") }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if device.platform == .ios { try checked("/usr/bin/xcrun", ["simctl", "io", device.id, "screenshot", url.path]) }
        else {
            let remote = "/sdcard/devbar-\(UUID().uuidString).png"
            let adb = Shell.shared.resolveAdbPath()
            defer { _ = Shell.shared.run(executable: adb, arguments: ["-s", device.id, "shell", "rm", remote]) }
            try checked(adb, ["-s", device.id, "shell", "screencap", "-p", remote])
            try checked(adb, ["-s", device.id, "pull", remote, url.path])
        }
        guard let size = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber, size.intValue > 0 else {
            throw DevBarError("Screenshot produced an empty file.")
        }
        return url.path
    }

    public func install(_ device: Device, path: String) throws {
        try requireRunning(device)
        let url = URL(fileURLWithPath: path).standardizedFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { throw DevBarError("Build does not exist: \(url.path)") }
        guard url.pathExtension == (device.platform == .ios ? "app" : "apk") else {
            throw DevBarError("Use a simulator-built .app for iOS or .apk for Android; device .ipa builds cannot run on simulators.")
        }
        if device.platform == .ios { try checked("/usr/bin/xcrun", ["simctl", "install", device.id, url.path], timeout: 120) }
        else { try checked(Shell.shared.resolveAdbPath(), ["-s", device.id, "install", "-r", url.path], timeout: 120) }
    }

    public func launch(_ device: Device, app: String) throws {
        try requireRunning(device)
        guard !app.isEmpty, app.range(of: "^[A-Za-z0-9_-]+(\\.[A-Za-z0-9_-]+)+$", options: .regularExpression) != nil else {
            throw DevBarError("Supply a valid bundle ID or package name.")
        }
        if device.platform == .ios { try checked("/usr/bin/xcrun", ["simctl", "launch", device.id, app]) }
        else { try checked(Shell.shared.resolveAdbPath(), ["-s", device.id, "shell", "monkey", "-p", app, "-c", "android.intent.category.LAUNCHER", "1"]) }
    }

    public func openURL(_ device: Device, url: String) throws {
        try requireRunning(device)
        guard let parsed = URL(string: url), let scheme = parsed.scheme, !scheme.isEmpty, !url.contains("\n") else { throw DevBarError("URL must include a scheme, such as myapp:// or https://.") }
        if device.platform == .ios { try checked("/usr/bin/xcrun", ["simctl", "openurl", device.id, url]) }
        else { try checked(Shell.shared.resolveAdbPath(), ["-s", device.id, "shell", "am", "start", "-a", "android.intent.action.VIEW", "-d", Self.remoteQuote(url)]) }
    }

    public func location(_ device: Device, latitude: Double, longitude: Double) throws {
        try Self.validateLocation(latitude, longitude)
        try requireRunning(device)
        guard !device.isPhysical else { throw DevBarError("Location spoofing requires a simulator or emulator.") }
        if device.platform == .ios { try checked("/usr/bin/xcrun", ["simctl", "location", device.id, "set", "\(latitude),\(longitude)"]) }
        else { try checked(Shell.shared.resolveAdbPath(), ["-s", device.id, "emu", "geo", "fix", "\(longitude)", "\(latitude)"]) }
    }

    public func doctor() -> [[String: Any]] {
        [("iOS tools", "/usr/bin/xcrun", ["simctl", "list", "devices", "-j"]),
         ("Android bridge", Shell.shared.resolveAdbPath(), ["version"]),
         ("Android emulator", Shell.shared.resolveEmulatorPath(), ["-version"])].map { name, executable, arguments in
            let result = Shell.shared.run(executable: executable, arguments: arguments, timeout: 10)
            return ["name": name, "available": result.status == 0, "path": executable,
                    "detail": result.status == 0 ? "Ready" : result.error]
        }
    }
}
