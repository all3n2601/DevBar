import Foundation

public enum DevicePlatform: String, Codable, Hashable, Identifiable {
    case ios = "iOS"
    case android = "Android"

    public var id: String { self.rawValue }

    public var iconName: String {
        switch self {
        case .ios: return "apple.logo"
        case .android: return "play.display" // macOS symbol for Android display
        }
    }
}

public enum DeviceState: String, Codable, Hashable, Identifiable {
    case booted = "Booted"
    case shutdown = "Shutdown"
    case booting = "Booting"

    public var id: String { self.rawValue }
}

public struct Device: Codable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let platform: DevicePlatform
    public var state: DeviceState
    public let osVersion: String
    public let isPhysical: Bool

    public init(id: String, name: String, platform: DevicePlatform, state: DeviceState, osVersion: String, isPhysical: Bool = false) {
        self.id = id
        self.name = name
        self.platform = platform
        self.state = state
        self.osVersion = osVersion
        self.isPhysical = isPhysical
    }

    // UI Helpers
    public var displayName: String {
        name
    }

    public var displayOS: String {
        switch platform {
        case .ios:
            return "iOS \(osVersion)"
        case .android:
            return "Android (API \(osVersion))"
        }
    }
}
