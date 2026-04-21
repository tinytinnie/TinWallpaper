import Foundation
import AVKit
import AppKit
import Combine
import ServiceManagement

@MainActor
final class WallpaperManager: ObservableObject {

    private static let debugLoggingEnabled = false

    private func log(_ message: String) {
        guard Self.debugLoggingEnabled else { return }
        let ts = String(format: "%.3f", Date().timeIntervalSince1970)
        print("[TinWallpaper][WallpaperManager][\(ts)] \(message)")
    }

    enum OutputMode: String, CaseIterable, Identifiable {
        case liveWallpaper
        case screensaver
        var id: String { rawValue }
        var title: String {
            switch self {
            case .liveWallpaper: return "Live Wallpaper"
            case .screensaver:   return "Screensaver"
            }
        }
    }

    @Published var player = AVPlayer()
    @Published var isPaused = false
    @Published var recentVideos: [URL] = []
    @Published var launchAtLogin: Bool = false {
        didSet {
            if #available(macOS 13.0, *) {
                if launchAtLogin { try? SMAppService.mainApp.register() }
                else { try? SMAppService.mainApp.unregister() }
            }
        }
    }
    @Published var outputMode: OutputMode = .liveWallpaper {
        didSet { UserDefaults.standard.set(outputMode.rawValue, forKey: "outputMode") }
    }

    private(set) var currentVideoURL: URL?
    private let recentKey       = "recentVideos"
    private let savedKey        = "savedVideoURL"
    private let liveVideoFileName        = "currentVideo.mp4"
    private let screensaverVideoFileName = "screensaverVideo.mp4"
    private let urlTextFileName           = "selectedVideoURL.txt"
    private let sharedDir       = URL(fileURLWithPath: "/Users/Shared/TinWallpaper", isDirectory: true)

    init() {
        if let savedMode = UserDefaults.standard.string(forKey: "outputMode"),
           let mode = OutputMode(rawValue: savedMode) { outputMode = mode }
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        createSharedDirIfNeeded()
        loadRecents()
        loadSaved()
        observeSystem()
    }

    // MARK: - Video Loading

    func loadVideo(url: URL) {
        let requestedMode = outputMode
        let destination: URL = {
            switch requestedMode {
            case .liveWallpaper:
                return sharedDir.appendingPathComponent("currentVideo-\(UUID().uuidString).mp4")
            case .screensaver:
                return managedVideoURL(for: requestedMode)
            }
        }()

        log("loadVideo requestedMode=\(requestedMode.rawValue) src=\(url.path) dst=\(destination.path)")

        // Already the managed file — apply directly
        if url.standardizedFileURL == destination.standardizedFileURL {
            currentVideoURL = destination
            UserDefaults.standard.set(destination.absoluteString, forKey: savedKey)
            writeURLText(destination)
            addRecent(url)
            applyVideo(destination, for: requestedMode)
            return
        }

        Task {
            log("begin async copy src=\(url.path)")
            let hasScope = url.startAccessingSecurityScopedResource()
            let src = url
            let dst = destination

            let copyError: Error? = await Task.detached(priority: .utility) {
                do {
                    let temp = dst.deletingLastPathComponent()
                        .appendingPathComponent(".tin-copy-\(UUID().uuidString).mp4")

                    try FileManager.default.copyItem(at: src, to: temp)

                    if FileManager.default.fileExists(atPath: dst.path) {
                        _ = try FileManager.default.replaceItemAt(dst, withItemAt: temp)
                    } else {
                        try FileManager.default.moveItem(at: temp, to: dst)
                    }

                    return nil
                } catch {
                    return error
                }
            }.value

            if hasScope { url.stopAccessingSecurityScopedResource() }
            if let copyError {
                log("copy finished with error: \(copyError.localizedDescription)")
                return
            }
            log("copy finished successfully dst=\(destination.path)")

            currentVideoURL = destination
            UserDefaults.standard.set(destination.absoluteString, forKey: savedKey)
            writeURLText(destination)
            addRecent(url)
            applyVideo(destination, for: requestedMode)
        }
    }

    func loadSaved() {
        if let str = UserDefaults.standard.string(forKey: savedKey),
           let url = URL(string: str),
           FileManager.default.fileExists(atPath: url.path) {
            currentVideoURL = url
            applyVideo(url, for: outputMode)
            return
        }

        let managed = sharedDir.appendingPathComponent(liveVideoFileName)
        if FileManager.default.fileExists(atPath: managed.path) {
            print("WallpaperManager: restoring from \(managed.path)")
            currentVideoURL = managed
            writeURLText(managed)
            applyVideo(managed, for: outputMode)
            return
        }

        print("WallpaperManager: no saved video found")
    }

    // MARK: - Mode Actions

    func applyCurrentToLiveWallpaper() {
        guard let url = currentVideoURL else { return }
        outputMode = .liveWallpaper
        // setupScreens handles its own safe teardown internally
        MultiScreenManager.shared.setupScreens(with: url)
    }

    func setCurrentForScreensaver() {
        guard let url = currentVideoURL else { return }
        outputMode = .screensaver
        writeURLText(url)
        print("WallpaperManager: screensaver source set to \(url.path)")
    }

    func changeOutputMode(to mode: OutputMode) {
        guard outputMode != mode else { return }
        outputMode = mode
    }

    var hasCurrentVideo: Bool { currentVideoURL != nil }

    // MARK: - Playback

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            player.pause()
            MultiScreenManager.shared.pauseAll()
        } else {
            if outputMode == .liveWallpaper { MultiScreenManager.shared.playAll() }
            else { player.play() }
        }
    }

    // MARK: - Recents

    func addRecent(_ url: URL) {
        recentVideos.removeAll { $0 == url }
        recentVideos.insert(url, at: 0)
        recentVideos = Array(recentVideos.prefix(10))
        saveRecents()
    }

    func loadRecents() {
        guard let arr = UserDefaults.standard.array(forKey: recentKey) as? [String] else { return }
        recentVideos = arr.compactMap { URL(string: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
        saveRecents()
    }

    private func saveRecents() {
        UserDefaults.standard.set(recentVideos.map { $0.absoluteString }, forKey: recentKey)
    }

    // MARK: - System Observers

    func observeSystem() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(systemSleep),
            name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(systemWake),
            name: NSWorkspace.didWakeNotification, object: nil)
    }

    @objc func systemSleep() {
        player.pause()
        MultiScreenManager.shared.pauseAll()
    }

    @objc func systemWake() {
        guard !isPaused else { return }
        if outputMode == .liveWallpaper { MultiScreenManager.shared.playAll() }
        else { player.play() }
    }

    // MARK: - Private

    private func applyVideo(_ url: URL, for mode: OutputMode) {
        log("applyVideo mode=\(mode.rawValue) url=\(url.path)")
        writeURLText(url)
        switch mode {
        case .liveWallpaper:
            DispatchQueue.main.async {
                self.log("calling setupScreens live url=\(url.path)")
                MultiScreenManager.shared.setupScreens(with: url)
                self.log("setupScreens returned")
            }
        case .screensaver:
            // Keep live wallpaper active; only update the screensaver source.
            break
        }
    }

    private func managedVideoURL(for mode: OutputMode) -> URL {
        let fileName = (mode == .liveWallpaper) ? liveVideoFileName : screensaverVideoFileName
        return sharedDir.appendingPathComponent(fileName)
    }

    private func writeURLText(_ url: URL) {
        let file = sharedDir.appendingPathComponent(urlTextFileName)
        do {
            try url.absoluteString.write(to: file, atomically: true, encoding: .utf8)
            print("WallpaperManager: wrote URL text → \(url.absoluteString)")
        } catch {
            print("WallpaperManager: failed to write URL text: \(error)")
        }
    }

    private func createSharedDirIfNeeded() {
        do {
            try FileManager.default.createDirectory(
                at: sharedDir, withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o755])
        } catch {
            print("WallpaperManager: shared dir error: \(error)")
        }
    }
}
