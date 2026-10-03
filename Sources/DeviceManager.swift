import DevBarCore
import Foundation
import Combine
import AppKit
import CoreLocation

// MARK: - Helper GPX Parser
class GPXParser: NSObject, XMLParserDelegate {
    var points: [CLLocationCoordinate2D] = []

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "trkpt" || elementName == "wpt" {
            if let latStr = attributeDict["lat"], let lat = Double(latStr),
               let lonStr = attributeDict["lon"], let lon = Double(lonStr) {
                points.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
    }
}

// MARK: - Helper Android SharedPreferences XML Parser
class SharedPreferencesParser: NSObject, XMLParserDelegate {
    var dict: [String: String] = [:]
    private var currentElement = ""
    private var currentKey = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if let key = attributeDict["name"] {
            currentKey = key
            if let val = attributeDict["value"] {
                dict[key] = val
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !currentKey.isEmpty {
            dict[currentKey] = trimmed
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == currentElement {
            currentKey = ""
        }
    }
}

public class DeviceManager: ObservableObject {
    @Published public var lastError: String?
    @Published public var devices: [Device] = []
    @Published public var isRefreshing = false
    @Published public var activeRecordings: Set<String> = []

    // GPX Playback Publisher States (Phase 3)
    @Published public var activeGpxCoordinate: CLLocationCoordinate2D? = nil
    @Published public var gpxPointsCount = 0
    @Published public var gpxPlaybackIndex = 0
    @Published public var isGpxPlaying = false

    private var cancellables = Set<AnyCancellable>()
    private let shell = Shell.shared

    // Asynchronous long-running process mapping for screen recording
    private var runningRecordingProcesses: [String: Process] = [:]
    private var activeRecordingPaths: [String: String] = [:]

    // GPX Playback Timer references
    private var gpxPoints: [CLLocationCoordinate2D] = []
    private var gpxTimer: Timer? = nil

    public init() {
        // Initial refresh
        refreshDevices()
    }

    /// Scans the host system for both iOS simulators and Android emulators.
    public func refreshDevices() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.refreshDevices() }
            return
        }
        guard !isRefreshing else { return }
        isRefreshing = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var allDevices: [Device] = []

            // 1. Fetch iOS Simulators
            let iosDevices = DeviceService().fetchIosDevices()
            allDevices.append(contentsOf: iosDevices)

            // 2. Fetch Android Emulators
            let androidDevices = DeviceService().fetchAndroidDevices()
            allDevices.append(contentsOf: androidDevices)

            DispatchQueue.main.async {
                self.devices = allDevices.sorted { $0.name.lowercased() < $1.name.lowercased() }
                self.isRefreshing = false
            }
        }
    }

    public func stopAllRecordings() {
        for process in runningRecordingProcesses.values where process.isRunning { process.interrupt() }
    }

    // MARK: - Device Operations

    /// Boots the selected device.
    public func bootDevice(_ device: Device) {
        updateDeviceState(id: device.id, to: .booting)
        performOperation {
            try DeviceService().boot(device)
            if device.platform == .ios { _ = self.shell.run(executable: "/usr/bin/open", arguments: ["-a", "Simulator"]) }
        }
    }

    public func shutdownDevice(_ device: Device) {
        performOperation { try DeviceService().shutdown(device) }
    }

    private func performOperation(_ operation: @escaping () throws -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do { try operation() }
            catch { DispatchQueue.main.async { self.lastError = error.localizedDescription } }
            DispatchQueue.main.async { self.refreshDevices() }
        }
    }

    // MARK: - Phase 1 MVP Feature Upgrades

    /// Installs a local application package onto a booted simulator or emulator.
    public func installApp(filePath: String, to device: Device, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try DeviceService().install(device, path: filePath)
                DispatchQueue.main.async { completion(true, "Installed on \(device.name).") }
            } catch {
                DispatchQueue.main.async { completion(false, error.localizedDescription) }
            }
        }
    }

    public func takeScreenshot(for device: Device, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let path = try DeviceService().screenshot(device, path: FileManager.default.temporaryDirectory.appendingPathComponent("DevBar-\(UUID().uuidString).png").path)
                DispatchQueue.main.async {
                    if let image = NSImage(contentsOfFile: path) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.writeObjects([image])
                    }
                    completion(true, "Screenshot saved: \(path)")
                }
            } catch { DispatchQueue.main.async { completion(false, error.localizedDescription) } }
        }
    }

    /// Starts a long-running video capture session for screen recording, outputs to ~/Downloads.
    public func startRecording(for device: Device, completion: @escaping (Bool, String) -> Void) {
        guard !activeRecordings.contains(device.id) else { completion(false, "Already recording this device."); return }
        guard device.state == .booted else {
            completion(false, "Device must be booted to record screens.")
            return
        }

        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let downloadsDir = "\(homeDir)/Downloads"
        let timestamp = Int(Date().timeIntervalSince1970)
        let cleanName = device.name.replacingOccurrences(of: " ", with: "_")
        let fileName = "DevBar_Record_\(cleanName)_\(timestamp).mp4"
        let outputPath = "\(downloadsDir)/\(fileName)"

        activeRecordingPaths[device.id] = outputPath

        switch device.platform {
        case .ios:
            let process = shell.runAsynchronousProcess(
                executable: "/usr/bin/xcrun",
                arguments: ["simctl", "io", device.id, "recordVideo", "--codec=h264", "--force", outputPath]
            )

            if let process = process {
                runningRecordingProcesses[device.id] = process
                activeRecordings.insert(device.id)
                completion(true, "iOS screen recording active...")
            } else {
                completion(false, "Failed to initialize iOS screen recorder.")
            }

        case .android:
            let adbPath = shell.resolveAdbPath()
            let process = shell.runAsynchronousProcess(
                executable: adbPath,
                arguments: ["-s", device.id, "shell", "screenrecord", "/sdcard/devbar_temp_rec.mp4"]
            )

            if let process = process {
                runningRecordingProcesses[device.id] = process
                activeRecordings.insert(device.id)
                completion(true, "Android screen recording active...")
            } else {
                completion(false, "Failed to initialize Android screen recorder.")
            }
        }
    }

    /// Stops an active screen recording session, flushes the stream, and copies it to ~/Downloads.
    public func stopRecording(for device: Device, completion: @escaping (Bool, String) -> Void) {
        guard activeRecordings.contains(device.id) else {
            completion(false, "No active recording found for this device.")
            return
        }

        guard let process = runningRecordingProcesses[device.id],
              let outputPath = activeRecordingPaths[device.id] else {
            completion(false, "Recording metadata corrupted.")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            if process.isRunning { process.interrupt() }
            let deadline = Date().addingTimeInterval(10)
            while process.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.05) }
            if process.isRunning { process.terminate() }
            let grace = Date().addingTimeInterval(1)
            while process.isRunning && Date() < grace { Thread.sleep(forTimeInterval: 0.05) }
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            process.waitUntilExit()

            var success = (process.terminationStatus == 0 || process.terminationStatus == 2)

            if device.platform == .android {
                let adbPath = self.shell.resolveAdbPath()
                let pullResult = self.shell.run(executable: adbPath, arguments: ["-s", device.id, "pull", "/sdcard/devbar_temp_rec.mp4", outputPath])
                success = pullResult.status == 0
                _ = self.shell.run(executable: adbPath, arguments: ["-s", device.id, "shell", "rm", "/sdcard/devbar_temp_rec.mp4"])
            }

            DispatchQueue.main.async {
                self.runningRecordingProcesses.removeValue(forKey: device.id)
                self.activeRecordingPaths.removeValue(forKey: device.id)
                self.activeRecordings.remove(device.id)

                if success {
                    let fileUrl = URL(fileURLWithPath: outputPath)
                    completion(true, "Video saved to Downloads: \(fileUrl.lastPathComponent)")
                } else {
                    completion(false, "Screen recording finalization failed.")
                }
            }
        }
    }

    /// Deep-wipes the device data caches (iOS Simulators) or boots Android emulators in factory-reset states.
    public func wipeDevice(_ device: Device) {
        guard device.platform == .ios else {
            lastError = "Android reset is not supported here. Use Android Studio Device Manager."
            return
        }
        performOperation {
            if device.state == .booted { try DeviceService().shutdown(device) }
            _ = try DeviceService().checked("/usr/bin/xcrun", ["simctl", "erase", device.id])
        }
    }

    // MARK: - Phase 2 Operations

    /// Sets the GPS location on all active devices.
    public func setGPSLocation(latitude: Double, longitude: Double, completion: @escaping (Bool) -> Void) {
        do { try DeviceService.validateLocation(latitude, longitude) }
        catch { lastError = error.localizedDescription; completion(false); return }
        let active = devices.filter { $0.state == .booted && !$0.isPhysical }
        guard !active.isEmpty else { completion(false); return }
        DispatchQueue.global(qos: .userInitiated).async {
            var errors: [String] = []
            for device in active {
                do { try DeviceService().location(device, latitude: latitude, longitude: longitude) }
                catch { errors.append("\(device.name): \(error.localizedDescription)") }
            }
            let message = errors.joined(separator: "\n")
            DispatchQueue.main.async {
                if !message.isEmpty { self.lastError = message }
                completion(message.isEmpty)
            }
        }
    }

    /// Toggles the Night/Dark mode appearance on all active devices.
    public func toggleAppearance(darkMode: Bool) {
        let activeBooted = devices.filter { $0.state == .booted }
        guard !activeBooted.isEmpty else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            for device in activeBooted {
                switch device.platform {
                case .ios:
                    let modeStr = darkMode ? "dark" : "light"
                    _ = self.shell.run(executable: "/usr/bin/xcrun", arguments: ["simctl", "ui", device.id, "appearance", modeStr])

                case .android:
                    let adbPath = self.shell.resolveAdbPath()
                    let modeStr = darkMode ? "yes" : "no"
                    _ = self.shell.run(executable: adbPath, arguments: ["-s", device.id, "shell", "cmd", "uimode", "night", modeStr])
                }
            }
        }
    }

    /// Toggles standard clean status bar overrides across active devices for App Store and GTM captures.
    public func toggleCleanStatusBar(enabled: Bool) {
        let activeBooted = devices.filter { $0.state == .booted }
        guard !activeBooted.isEmpty else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            for device in activeBooted {
                switch device.platform {
                case .ios:
                    if enabled {
                        _ = self.shell.run(
                            executable: "/usr/bin/xcrun",
                            arguments: ["simctl", "status_bar", device.id, "override", "--time", "9:41", "--batteryState", "charged", "--batteryLevel", "100", "--cellularBars", "4"]
                        )
                    } else {
                        _ = self.shell.run(executable: "/usr/bin/xcrun", arguments: ["simctl", "status_bar", device.id, "clear"])
                    }

                case .android:
                    let adbPath = self.shell.resolveAdbPath()
                    if enabled {
                        _ = self.shell.run(executable: adbPath, arguments: ["-s", device.id, "shell", "settings", "put", "global", "sysui_demo_allowed", "1"])
                        _ = self.shell.run(executable: adbPath, arguments: ["-s", device.id, "shell", "am", "broadcast", "-a", "com.android.systemui.demo", "-e", "command", "clock", "-e", "hhmm", "0900"])
                        _ = self.shell.run(executable: adbPath, arguments: ["-s", device.id, "shell", "am", "broadcast", "-a", "com.android.systemui.demo", "-e", "command", "network", "-e", "mobile", "show", "-e", "datatype", "lte", "-e", "level", "4"])
                        _ = self.shell.run(executable: adbPath, arguments: ["-s", device.id, "shell", "am", "broadcast", "-a", "com.android.systemui.demo", "-e", "command", "battery", "-e", "level", "100", "-e", "plugged", "false"])
                    } else {
                        _ = self.shell.run(executable: adbPath, arguments: ["-s", device.id, "shell", "am", "broadcast", "-a", "com.android.systemui.demo", "-e", "command", "exit"])
                    }
                }
            }
        }
    }

    /// Injects a mock push notification JSON payload into a booted device app.
    public func injectPushNotification(payloadPath: String, bundleId: String, completion: @escaping (Bool, String) -> Void) {
        let activeBooted = devices.filter { $0.state == .booted }
        guard !activeBooted.isEmpty else {
            completion(false, "No active devices available.")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var success = true
            var errorMsg = ""

            guard let payload = try? Data(contentsOf: URL(fileURLWithPath: payloadPath)),
                  (try? JSONSerialization.jsonObject(with: payload)) is [String: Any] else {
                DispatchQueue.main.async {
                    completion(false, "Failed to read payload JSON file content.")
                }
                return
            }

            for device in activeBooted {
                switch device.platform {
                case .ios:
                    let result = self.shell.run(
                        executable: "/usr/bin/xcrun",
                        arguments: ["simctl", "push", device.id, bundleId, payloadPath]
                    )
                    if result.status != 0 {
                        success = false
                        errorMsg = result.error
                    }

                case .android:
                    success = false
                    errorMsg = "Android FCM injection is unsupported; send through your test backend."

                }
            }

            DispatchQueue.main.async {
                if success {
                    completion(true, "Push payload injected successfully!")
                } else {
                    completion(false, "Injection failed: \(errorMsg.isEmpty ? "Unknown system error" : errorMsg)")
                }
            }
        }
    }

    // MARK: - Phase 3 Operations

    /// Parses a dropped GPX XML track log and sets up playback coordinates.
    public func loadGPXFile(path: String) -> Int {
        guard let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else { return 0 }
        let delegate = GPXParser()
        parser.delegate = delegate

        if parser.parse() {
            gpxPoints = delegate.points
            DispatchQueue.main.async { [weak self] in
                self?.gpxPointsCount = delegate.points.count
                self?.gpxPlaybackIndex = 0
                self?.activeGpxCoordinate = delegate.points.first
            }
            return delegate.points.count
        }
        return 0
    }

    /// Periodically playbacks parsed GPX trackpoints to simulate device movement.
    public func startGPXPlayback(interval: TimeInterval = 1.0) {
        guard !gpxPoints.isEmpty else { return }
        stopGPXPlayback()

        isGpxPlaying = true

        gpxTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.gpxPlaybackIndex >= self.gpxPoints.count {
                self.gpxPlaybackIndex = 0 // Loop
            }

            let coord = self.gpxPoints[self.gpxPlaybackIndex]
            self.activeGpxCoordinate = coord

            // Spoof GPS location concurrently across running emulators
            self.setGPSLocation(latitude: coord.latitude, longitude: coord.longitude) { _ in }

            self.gpxPlaybackIndex += 1
        }
    }

    /// Invalidates and releases the active GPX playback timer.
    public func stopGPXPlayback() {
        gpxTimer?.invalidate()
        gpxTimer = nil
        isGpxPlaying = false
    }

    /// Fires target custom URL schemes / deep links across active booted devices.
    public func launchDeeplink(url: String, completion: @escaping (Bool, String) -> Void) {
        let activeBooted = devices.filter { $0.state == .booted }
        guard !activeBooted.isEmpty else {
            completion(false, "No active devices available.")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var success = true
            var errorMsg = ""

            for device in activeBooted {
                switch device.platform {
                case .ios:
                    let result = self.shell.run(executable: "/usr/bin/xcrun", arguments: ["simctl", "openurl", device.id, url])
                    if result.status == 0 { success = true } else { errorMsg = result.error }

                case .android:
                    let adbPath = self.shell.resolveAdbPath()
                    let result = self.shell.run(executable: adbPath, arguments: ["-s", device.id, "shell", "am", "start", "-a", "android.intent.action.VIEW", "-d", DeviceService.remoteQuote(url)])
                    if result.status == 0 { success = true } else { errorMsg = result.error }
                }
            }

            DispatchQueue.main.async {
                if success {
                    completion(true, "Deeplink launched successfully!")
                } else {
                    completion(false, "Failed to launch: \(errorMsg.isEmpty ? "Unknown CLI error" : errorMsg)")
                }
            }
        }
    }

    /// Dynamic local plist / XML Preferences loader.
    public func loadStorageKeys(bundleId: String, completion: @escaping ([String: String]?) -> Void) {
        let activeBooted = devices.filter { $0.state == .booted }
        guard let device = activeBooted.first else {
            completion(nil)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            switch device.platform {
            case .ios:
                // Find iOS Sandbox Path
                let containerResult = self.shell.run(executable: "/usr/bin/xcrun", arguments: ["simctl", "get_app_container", device.id, bundleId, "data"])
                guard containerResult.status == 0 else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                let plistPath = "\(containerResult.output)/Library/Preferences/\(bundleId).plist"
                if FileManager.default.fileExists(atPath: plistPath),
                   let dict = NSDictionary(contentsOfFile: plistPath) as? [String: Any] {
                    var out: [String: String] = [:]
                    for (key, val) in dict {
                        out[key] = String(describing: val)
                    }
                    DispatchQueue.main.async { completion(out) }
                } else {
                    DispatchQueue.main.async { completion([:]) } // Empty preference file initialized
                }

            case .android:
                // Pull SharedPreferences XML
                let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("DevBar").path
                try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true, attributes: nil)

                let localXmlPath = "\(tempDir)/\(bundleId)_prefs.xml"
                let adbPath = self.shell.resolveAdbPath()

                let pullResult = self.shell.run(executable: adbPath, arguments: ["-s", device.id, "pull", "/data/data/\(bundleId)/shared_prefs/\(bundleId)_preferences.xml", localXmlPath])
                guard pullResult.status == 0 else {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                // Parse preferences XML
                if let parser = XMLParser(contentsOf: URL(fileURLWithPath: localXmlPath)) {
                    let delegate = SharedPreferencesParser()
                    parser.delegate = delegate
                    if parser.parse() {
                        try? FileManager.default.removeItem(atPath: localXmlPath)
                        DispatchQueue.main.async { completion(delegate.dict) }
                        return
                    }
                }
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }

    /// Dynamic local plist / XML Preferences modifier.
    public func saveStorageKey(key: String, value: String, bundleId: String, completion: @escaping (Bool) -> Void) {
        let activeBooted = devices.filter { $0.state == .booted }
        guard let device = activeBooted.first else {
            completion(false)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            switch device.platform {
            case .ios:
                let containerResult = self.shell.run(executable: "/usr/bin/xcrun", arguments: ["simctl", "get_app_container", device.id, bundleId, "data"])
                guard containerResult.status == 0 else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }

                let plistPath = "\(containerResult.output)/Library/Preferences/\(bundleId).plist"
                let dict = NSMutableDictionary(contentsOfFile: plistPath) ?? NSMutableDictionary()
                dict.setObject(value, forKey: key as NSCopying)

                let success = dict.write(toFile: plistPath, atomically: true)
                DispatchQueue.main.async { completion(success) }

            case .android:
                // Android edit: Pull, modify string element in XML, and push back
                let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("DevBar").path
                try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true, attributes: nil)

                let localXmlPath = "\(tempDir)/\(bundleId)_prefs.xml"
                let adbPath = self.shell.resolveAdbPath()

                let pullResult = self.shell.run(executable: adbPath, arguments: ["-s", device.id, "pull", "/data/data/\(bundleId)/shared_prefs/\(bundleId)_preferences.xml", localXmlPath])

                // Read pulled XML
                var xmlString = ""
                if pullResult.status == 0,
                   let existingXml = try? String(contentsOfFile: localXmlPath, encoding: .utf8) {
                    xmlString = existingXml
                } else {
                    xmlString = "<?xml version='1.0' encoding='utf-8' standalone='yes'?>\n<map>\n</map>"
                }

                // Check if key exists inside XML and modify or add it
                var success = false
                let keyPattern = "name=\"\(key)\""
                if xmlString.contains(keyPattern) {
                    // Regex replacement for target key line (string, boolean, int, etc.)
                    // Simple replacement for demonstration, standard: replace the XML line
                    let lines = xmlString.components(separatedBy: .newlines)
                    var outLines: [String] = []
                    for line in lines {
                        if line.contains(keyPattern) {
                            outLines.append("    <string name=\"\(key)\">\(value)</string>")
                        } else {
                            outLines.append(line)
                        }
                    }
                    xmlString = outLines.joined(separator: "\n")
                } else {
                    // Inject new string key before closing </map>
                    xmlString = xmlString.replacingOccurrences(of: "</map>", with: "    <string name=\"\(key)\">\(value)</string>\n</map>")
                }

                // Write XML back and push
                if (try? xmlString.write(toFile: localXmlPath, atomically: true, encoding: .utf8)) != nil {
                    let pushResult = self.shell.run(executable: adbPath, arguments: ["-s", device.id, "push", localXmlPath, "/data/data/\(bundleId)/shared_prefs/\(bundleId)_preferences.xml"])
                    if pushResult.status == 0 {
                        success = true
                    }
                    try? FileManager.default.removeItem(atPath: localXmlPath)
                }

                DispatchQueue.main.async { completion(success) }
            }
        }
    }

    private func updateDeviceState(id: String, to state: DeviceState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let index = self.devices.firstIndex(where: { $0.id == id }) {
                self.devices[index].state = state
            }
        }
    }
}
