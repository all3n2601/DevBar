import DevBarCore
import Cocoa
import SwiftUI

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarItem: NSStatusItem!
    private var popover: NSPopover!
    private let manager = DeviceManager()

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Hide from Dock (Accessory Mode)
        NSApp.setActivationPolicy(.accessory)

        // 2. Build SwiftUI popover container
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 500)
        popover.behavior = .transient // Closes automatically when clicking outside
        popover.contentViewController = NSHostingController(rootView: MainView(manager: manager))
        self.popover = popover

        // 3. Create macOS Menu Bar status item
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = self.statusBarItem.button {
            button.image = Self.menuBarIcon()
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // 4. Register global system keyboard shortcut (Option + Shift + D)
        ShortcutManager.shared.registerShortcut { [weak self] in
            self?.togglePopover(nil)
        }
    }

    private static func menuBarIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 20), flipped: false) { _ in
            NSColor.black.setStroke()
            let phone = NSBezierPath(roundedRect: NSRect(x: 4, y: 1, width: 12, height: 18), xRadius: 2.5, yRadius: 2.5)
            phone.lineWidth = 1.5
            phone.stroke()
            let terminal = NSBezierPath()
            terminal.move(to: NSPoint(x: 7, y: 12))
            terminal.line(to: NSPoint(x: 10, y: 10))
            terminal.line(to: NSPoint(x: 7, y: 8))
            terminal.move(to: NSPoint(x: 11, y: 8))
            terminal.line(to: NSPoint(x: 13, y: 8))
            terminal.lineWidth = 1.5
            terminal.lineCapStyle = .round
            terminal.lineJoinStyle = .round
            terminal.stroke()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "DevBar"
        return image
    }

    public func applicationWillTerminate(_ notification: Notification) {
        manager.stopAllRecordings()
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = self.statusBarItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            // Refresh device states on open so user gets real-time data
            manager.refreshDevices()

            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // Ensure keyboard events can register in popover textfields
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
