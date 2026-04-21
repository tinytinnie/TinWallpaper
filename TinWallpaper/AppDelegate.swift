import Cocoa
import ServiceManagement
 
class AppDelegate: NSObject, NSApplicationDelegate {
 
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register as a login item so the wallpaper persists across reboots
        registerLoginItem()
        // Ensure the window appears correctly
        DispatchQueue.main.async {
            guard let window = NSApplication.shared.windows.first else { return }
            window.level = .normal
            window.makeKeyAndOrderFront(nil)
        }
    }
 
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running in background so wallpaper stays active
        return false
    }
 
    private func registerLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                // Registers the app itself as a login item (runs at login)
                try SMAppService.mainApp.register()
            } catch {
                print("Failed to register login item: \(error)")
            }
        }
    }
 
    /// Call this to unregister (e.g. from a "Launch at Login" toggle)
    static func unregisterLoginItem() {
        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.unregister()
        }
    }
 
    /// Returns whether the app is currently registered as a login item
    static var isRegisteredAsLoginItem: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
}
