//
//  HotKey.swift
//  SuperCursor
//

import Carbon.HIToolbox
import os

/// Something that can claim a system-wide keyboard shortcut. Lets tests use a fake.
protocol HotKeyRegistering: AnyObject {
    var onPress: (() -> Void)? { get set }
    func register()
    func unregister()
}

/// A system-wide keyboard shortcut. Uses Carbon's hot key API, which works inside
/// the App Sandbox and doesn't need Accessibility permission.
final class HotKey: HotKeyRegistering {
    var onPress: (() -> Void)?

    private let keyCode: UInt32
    private let modifiers: UInt32
    private let id: EventHotKeyID
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    private static let signature: OSType = 0x5343_5253  // "SCRS"
    private static var nextID: UInt32 = 1
    private static let logger = Logger(subsystem: "gustavssondevelopment.SuperCursor", category: "HotKey")

    /// Defaults to ⌥Space. Modifiers are Carbon flags such as `optionKey` or `cmdKey`.
    init(keyCode: Int = kVK_Space, modifiers: Int = optionKey) {
        self.keyCode = UInt32(keyCode)
        self.modifiers = UInt32(modifiers)
        id = EventHotKeyID(signature: Self.signature, id: Self.nextID)
        Self.nextID += 1
    }

    isolated deinit {
        unregister()
    }

    // DIAGNOSTIC (temporary): skips Carbon registration to test whether it breaks menu clicks.
    private static let diagnosticSkipRegistration = true

    func register() {
        if Self.diagnosticSkipRegistration { return }
        guard hotKeyRef == nil else { return }

        var pressed = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyHandler,
            1,
            &pressed,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )

        let status = RegisterEventHotKey(
            keyCode, modifiers, id, GetApplicationEventTarget(), 0, &hotKeyRef
        )
        if status != noErr {
            Self.logger.error("Couldn't register keyboard shortcut (status \(status))")
            unregister()
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    /// Returns whether the press was for this shortcut.
    fileprivate func handlePress(of pressedID: EventHotKeyID) -> Bool {
        guard pressedID.signature == id.signature, pressedID.id == id.id else {
            return false
        }
        onPress?()
        return true
    }
}

/// Carbon calls this on the main thread for every hot key press in the app.
private nonisolated func hotKeyHandler(
    _ next: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }

    var pressedID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &pressedID
    )
    guard status == noErr else { return status }

    let hotKey = Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue()
    let handled = MainActor.assumeIsolated { hotKey.handlePress(of: pressedID) }
    return handled ? noErr : OSStatus(eventNotHandledErr)
}
