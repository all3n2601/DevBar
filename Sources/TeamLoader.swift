import DevBarCore
import Foundation

public struct TeamGpsPreset: Codable, Identifiable {
    public var id = UUID()
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let icon: String

    enum CodingKeys: String, CodingKey {
        case name, latitude, longitude, icon
    }
}

public struct TeamPushPayload: Codable, Identifiable {
    public var id = UUID()
    public let name: String
    public let bundleId: String
    public let payloadString: String

    enum CodingKeys: String, CodingKey {
        case name, bundleId, payloadString
    }
}

public struct TeamConfig: Codable {
    public let gpsPresets: [TeamGpsPreset]?
    public let pushPayloads: [TeamPushPayload]?
}

public class TeamLoader {
    public static let shared = TeamLoader()

    public var teamConfig: TeamConfig?

    private init() {
        loadConfig()
    }

    /// Scans the workspace directory for a devbar.config.json configuration.
    public func loadConfig() {
        teamConfig = nil
        let configPath = ProcessInfo.processInfo.environment["DEVBAR_CONFIG"]
            ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("devbar.config.json").path

        guard FileManager.default.fileExists(atPath: configPath) else {
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
            let decoder = JSONDecoder()
            self.teamConfig = try decoder.decode(TeamConfig.self, from: data)
            print("Successfully loaded team workspace configuration.")
        } catch {
            print("Failed to parse devbar.config.json: \(error.localizedDescription)")
        }
    }
}
