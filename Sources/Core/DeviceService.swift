import Foundation

public final class DeviceService {
    public typealias Runner = (String, [String], TimeInterval) -> ShellResult
    public let runner: Runner
    public init(runner: @escaping Runner = { Shell.shared.run(executable: $0, arguments: $1, timeout: $2) }) {
        self.runner = runner
    }
    public func devices() -> [Device] { (fetchIosDevices() + fetchAndroidDevices()).sorted { $0.name < $1.name } }
    // MARK: - iOS Simulators

    private struct SimctlDeviceJson: Codable {
        let udid: String
        let state: String
        let name: String
        let isAvailable: Bool?
    }

    private struct SimctlListJson: Codable {
        let devices: [String: [SimctlDeviceJson]]
    }

    public func fetchIosDevices() -> [Device] {
        let result = runner("/usr/bin/xcrun", ["simctl", "list", "devices", "-j"], 15)
        guard result.status == 0, let data = result.output.data(using: .utf8) else {
            return []
        }

        do {
            return try Self.parseIosDevices(data)
        } catch {
            FileHandle.standardError.write(Data("Error parsing simctl output: \(error)\n".utf8))
            return []
        }
    }

    public static func parseIosDevices(_ data: Data) throws -> [Device] {
            let decoder = JSONDecoder()
            let rawList = try decoder.decode(SimctlListJson.self, from: data)
            var list: [Device] = []

            for (runtimeKey, runtimeDevices) in rawList.devices {
                guard runtimeKey.contains("SimRuntime.iOS") || runtimeKey.contains(".iOS-") else {
                    continue
                }

                let osVersion = Self.parseIosVersion(from: runtimeKey)

                for sim in runtimeDevices {
                    if let isAvailable = sim.isAvailable, !isAvailable {
                        continue
                    }

                    let state: DeviceState = (sim.state == "Booted") ? .booted : (sim.state == "Booting" ? .booting : .shutdown)

                    list.append(Device(
                        id: sim.udid,
                        name: sim.name,
                        platform: .ios,
                        state: state,
                        osVersion: osVersion
                    ))
                }
            }
            return list
    }

    public static func parseIosVersion(from runtimeKey: String) -> String {
        let components = runtimeKey.components(separatedBy: "iOS-")
        if components.count > 1 {
            let versionPart = components[1]
            return versionPart.replacingOccurrences(of: "-", with: ".")
        }
        return "Unknown"
    }

    // MARK: - Android Emulators

    public func fetchAndroidDevices() -> [Device] {
        var list: [Device] = []
        let adbPath = Shell.shared.resolveAdbPath()

        // 1. Get running emulators via adb
        let adbResult = runner(adbPath, ["devices"], 10)
        var runningAvdNames = Set<String>()

        if adbResult.status == 0 {
            let lines = adbResult.output.components(separatedBy: .newlines)
            for line in lines {
                let parts = line.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter { !$0.isEmpty }
                guard parts.count >= 2, parts[1] == "device" else { continue }
                let serial = parts[0]

                let avdName = fetchAndroidProperty(serial: serial, property: "ro.boot.qemu.avd_name")
                let sdkVersion = fetchAndroidProperty(serial: serial, property: "ro.build.version.sdk")

                let resolvedName = avdName.isEmpty ? serial : avdName.replacingOccurrences(of: "_", with: " ")
                if !avdName.isEmpty {
                    runningAvdNames.insert(avdName)
                }

                let apiStr = sdkVersion

                list.append(Device(
                    id: serial,
                    name: resolvedName,
                    platform: .android,
                    state: .booted,
                    osVersion: apiStr,
                    isPhysical: !serial.hasPrefix("emulator-")
                ))
            }
        }

        // 2. Get all configured offline emulators using emulator -list-avds
        let emulatorPath = Shell.shared.resolveEmulatorPath()
        let listAvdsResult = runner(emulatorPath, ["-list-avds"], 10)

        if listAvdsResult.status == 0 {
            let avdLines = listAvdsResult.output.components(separatedBy: .newlines).filter { !$0.isEmpty }
            for avd in avdLines {
                guard !runningAvdNames.contains(avd) else { continue }
                let resolvedName = avd.replacingOccurrences(of: "_", with: " ")
                let osVersion = parseAndroidVersionFromAvd(avd)

                list.append(Device(
                    id: avd,
                    name: resolvedName,
                    platform: .android,
                    state: .shutdown,
                    osVersion: osVersion
                ))
            }
        }

        return list
    }

    public func fetchAndroidProperty(serial: String, property: String) -> String {
        let adbPath = Shell.shared.resolveAdbPath()
        let result = runner(adbPath, ["-s", serial, "shell", "getprop", property], 5)
        return result.status == 0 ? result.output.trimmingCharacters(in: .whitespacesAndNewlines) : ""
    }

    public func parseAndroidVersionFromAvd(_ avdName: String) -> String {
        let components = avdName.components(separatedBy: "API_")
        if components.count > 1 {
            return components[1].components(separatedBy: "_")[0]
        }
        return "AVD"
    }

}
