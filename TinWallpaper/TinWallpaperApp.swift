import SwiftUI

@main
struct LiveWallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var updateManager = UpdateManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(updateManager)
                .task {
                    updateManager.performStartupCheckIfNeeded()
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    Task {
                        await updateManager.checkForUpdates(manual: true)
                    }
                }

                Toggle(
                    "Check for Updates Automatically",
                    isOn: $updateManager.autoCheckEnabled
                )
            }
        }
    }
}
