import Foundation

enum DarwinNotification: String {
    case liveActivityUpdateRequested = "com.checklistapp.liveactivity.update"
}

class DarwinNotificationCenter {
    static let shared = DarwinNotificationCenter()

    private let notificationCenter: CFNotificationCenter

    private init() {
        notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
    }

    func post(_ notification: DarwinNotification) {
        CFNotificationCenterPostNotification(
            notificationCenter,
            CFNotificationName(notification.rawValue as CFString),
            nil,
            nil,
            true
        )
    }

    func observe(_ notification: DarwinNotification, callback: @escaping () -> Void) {
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

        // Store callback
        CallbackStore.shared.callbacks[notification.rawValue] = callback

        CFNotificationCenterAddObserver(
            notificationCenter,
            observer,
            { (_, observer, name, _, _) in
                guard let name = name else { return }
                let notificationName = name.rawValue as String
                CallbackStore.shared.callbacks[notificationName]?()
            },
            notification.rawValue as CFString,
            nil,
            .deliverImmediately
        )
    }

    func removeObserver(_ notification: DarwinNotification) {
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterRemoveObserver(
            notificationCenter,
            observer,
            CFNotificationName(notification.rawValue as CFString),
            nil
        )
        CallbackStore.shared.callbacks.removeValue(forKey: notification.rawValue)
    }
}

private class CallbackStore {
    static let shared = CallbackStore()
    var callbacks: [String: () -> Void] = [:]
}
