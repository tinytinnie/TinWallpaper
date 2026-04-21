import AppKit
import AVKit

@MainActor
class MultiScreenManager {

    private static let debugLoggingEnabled = false

    private func log(_ message: String) {
        guard Self.debugLoggingEnabled else { return }
        let ts = String(format: "%.3f", Date().timeIntervalSince1970)
        print("[TinWallpaper][MultiScreenManager][\(ts)] \(message)")
    }

    static let shared = MultiScreenManager()

    private var windows: [NSWindow] = []
    private var players: [AVPlayer] = []
    private var playerLayers: [AVPlayerLayer] = []
    private var loopObservers: [NSObjectProtocol] = []

    // MARK: - Public

    func setupScreens(with url: URL) {
        log("setupScreens start url=\(url.path) windows=\(windows.count) players=\(players.count)")
        if canReuseCurrentWindows() {
            log("setupScreens path=reuse")
            updateExistingPlayers(with: url)
        } else {
            log("setupScreens path=rebuild")
            teardown()
            buildScreens(with: url)
        }
        log("setupScreens end")
    }

    func pauseAll() { players.forEach { $0.pause() } }
    func playAll()  { players.forEach { $0.play() } }
    func clear()    { teardown() }

    // MARK: - Teardown

    private func teardown() {
        NotificationCenter.default.removeObserver(
            self, name: NSApplication.didChangeScreenParametersNotification, object: nil)
        loopObservers.forEach { NotificationCenter.default.removeObserver($0) }
        loopObservers.removeAll()

        // Stop playback and detach from layers on main thread — safe and synchronous
        players.forEach { $0.pause() }
        playerLayers.forEach { $0.player = nil }

        // Capture for deferred close
        let dyingWindows = windows
        windows.removeAll()
        playerLayers.removeAll()
        players.removeAll()

        // Defer window close by one runloop cycle — lets CALayer finish any
        // in-progress display callbacks before the window is deallocated
        DispatchQueue.main.async {
            dyingWindows.forEach { $0.close() }
        }
    }

    // MARK: - Build

    private func buildScreens(with url: URL) {
        for screen in NSScreen.screens {
            let item = AVPlayerItem(url: url)
            item.preferredForwardBufferDuration = 0

            let player = AVPlayer(playerItem: item)
            player.isMuted = true
            player.actionAtItemEnd = .none
            player.automaticallyWaitsToMinimizeStalling = false
            players.append(player)
            attachLoop(to: player)

            let window = makeWallpaperWindow(for: screen, player: player)
            windows.append(window)
            player.play()
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    private func canReuseCurrentWindows() -> Bool {
        return !windows.isEmpty
            && windows.count == NSScreen.screens.count
            && players.count == windows.count
            && playerLayers.count == windows.count
    }

    private func updateExistingPlayers(with url: URL) {
        log("updateExistingPlayers start url=\(url.path) players=\(players.count)")
        loopObservers.forEach { NotificationCenter.default.removeObserver($0) }
        loopObservers.removeAll()

        for (index, player) in players.enumerated() {
            let item = AVPlayerItem(url: url)
            item.preferredForwardBufferDuration = 0

            player.replaceCurrentItem(with: item)
            player.actionAtItemEnd = .none
            player.automaticallyWaitsToMinimizeStalling = false
            attachLoop(to: player)
            player.play()
            log("player[\(index)] replaced+play tcs=\(player.timeControlStatus.rawValue) itemStatus=\(item.status.rawValue)")
        }
        log("updateExistingPlayers end")
    }

    private func makeWallpaperWindow(for screen: NSScreen, player: AVPlayer) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        window.isOpaque = true
        window.backgroundColor = .black
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.animationBehavior = .none

        let rootView = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        rootView.wantsLayer = true
        let rootLayer = CALayer()
        rootLayer.frame = rootView.bounds
        rootView.layer = rootLayer

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = rootLayer.bounds
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        rootLayer.addSublayer(playerLayer)
        playerLayers.append(playerLayer)

        window.contentView = rootView
        window.setFrame(screen.frame, display: false)
        window.orderFrontRegardless()
        return window
    }

    @objc private func screensChanged() {
        guard let first = players.first,
              let url = (first.currentItem?.asset as? AVURLAsset)?.url else { return }
        setupScreens(with: url)
    }

    private func attachLoop(to player: AVPlayer) {
        let observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in player.seek(to: .zero) { _ in player.play() } }
        loopObservers.append(observer)
    }
}
