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
            // Elegant developer tool symbol
            button.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "DevBar")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // 4. Register global system keyboard shortcut (Option + Shift + D)
        ShortcutManager.shared.registerShortcut { [weak self] in
            self?.togglePopover(nil)
        }
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
