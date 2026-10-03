import DevBarCore
import Cocoa
import Carbon

public class ShortcutManager {
    public static let shared = ShortcutManager()

    // OSType for 'DVBR' signature (D: 0x44, V: 0x56, B: 0x42, R: 0x52)
    private let hotKeyID = EventHotKeyID(signature: UInt32(0x44564252), id: 1)
    private var hotKeyRef: EventHotKeyRef?
    private var actionBlock: (() -> Void)?

    private init() {}

    /// Registers a system-wide global hotkey (Option + Shift + D) to trigger the provided action.
    public func registerShortcut(action: @escaping () -> Void) {
        self.actionBlock = action

        // Event spec matching kEventClassKeyboard (keyb: 0x6B657962) and kEventHotKeyPressed (15)
        var eventType = EventTypeSpec(eventClass: UInt32(0x6B657962), eventKind: 15)

        let handlerProc: EventHandlerUPP = { (nextHandler, event, userData) -> OSStatus in
            guard let event = event else { return OSStatus(eventNotHandledErr) }

            var hotKeyID = EventHotKeyID()
            // kEventParamDirectObject = 'dobj' (0x646F626A), typeEventHotKeyID = 'hkid' (0x686B6964)
            let status = GetEventParameter(
                event,
                UInt32(0x646F626A),
                UInt32(0x686B6964),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            if status == noErr && hotKeyID.signature == UInt32(0x44564252) {
                DispatchQueue.main.async {
                    ShortcutManager.shared.actionBlock?()
                }
                return noErr
            }
            return OSStatus(eventNotHandledErr)
        }

        var handler: EventHandlerRef?
        let result = InstallEventHandler(
            GetApplicationEventTarget(),
            handlerProc,
            1,
            &eventType,
            nil,
            &handler
        )

        if result == noErr {
            // Modifiers: optionKey = 0x0800 (2048), shiftKey = 0x0200 (512)
            // Carbon virtual key code for 'D' is 2
            let modifiers = UInt32(optionKey | shiftKey)
            let keyCode = UInt32(2)

            var hotRef: EventHotKeyRef?
            let registerResult = RegisterEventHotKey(
                keyCode,
                modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotRef
            )

            if registerResult == noErr {
                self.hotKeyRef = hotRef
                print("Global hotkey (Option + Shift + D) successfully registered.")
            } else {
                print("Failed to register global hotkey (error code: \(registerResult)).")
            }
        } else {
            print("Failed to install global hotkey event handler (error code: \(result)).")
        }
    }
}
