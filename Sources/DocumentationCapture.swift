#if DEBUG
import AppKit
import SwiftUI
import DevBarCore

/// Render the real SwiftUI views with reproducible demo data for README previews.
enum DocumentationCapture {
    static func run(directory: String) throws {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let manager = DeviceManager()
        // Drain the initial refresh, then set explicitly labeled demo devices.
        let deadline = Date().addingTimeInterval(30)
        while manager.isRefreshing && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        manager.devices = [
            Device(id: "demo-ios", name: "iPhone 17 Pro", platform: .ios, state: .booted, osVersion: "26.5"),
            Device(id: "demo-android", name: "Pixel 9 API 35", platform: .android, state: .booted, osVersion: "35"),
            Device(id: "demo-ipad", name: "iPad Pro 13-inch", platform: .ios, state: .shutdown, osVersion: "26.5")
        ]
        manager.isRefreshing = false
        let output = URL(fileURLWithPath: directory)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        try capture(MainView(manager: manager), to: output.appendingPathComponent("devices.png"))
        try capture(MainView(manager: manager, initialTab: .tools), to: output.appendingPathComponent("tools.png"))
    }

    private static func capture<Content: View>(_ content: Content, to url: URL) throws {
        let view = NSHostingView(rootView: content)
        let bounds = NSRect(x: 0, y: 0, width: 360, height: 500)
        let window = NSWindow(contentRect: bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = view
        view.frame = bounds
        window.orderFront(nil)
        view.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: bounds) else { throw DevBarError("Cannot create documentation image.") }
        view.cacheDisplay(in: bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { throw DevBarError("Cannot encode documentation image.") }
        try data.write(to: url)
        window.orderOut(nil)
    }
}
#endif
