import ScreenSaver
import AVKit
import AVFoundation

// Principal class in Info.plist must be:
//   TinWallpaperScreensaver.TinWallpaperScreensaverView
public class TinWallpaperScreensaverView: ScreenSaverView {

    private var playerViewController: NSViewController?
    private var player: AVPlayer?
    private let sharedDir = URL(fileURLWithPath: "/Users/Shared/TinWallpaper")

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setup()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        guard let url = videoURL() else {
            NSLog("[TinWallpaperScreensaver] No readable video URL was found.")
            return
        }

        try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.actionAtItemEnd = .none
        self.player = player

        let playerView = AVPlayerView(frame: bounds)
        playerView.player = player
        playerView.videoGravity = .resizeAspectFill
        playerView.controlsStyle = .none
        playerView.autoresizingMask = [.width, .height]

        let controller = NSViewController()
        controller.view = playerView
        self.playerViewController = controller
        addSubview(controller.view)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loopVideo),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }

    public override func startAnimation() {
        super.startAnimation()
        player?.play()
    }

    public override func stopAnimation() {
        super.stopAnimation()
        player?.pause()
    }

    public override func animateOneFrame() {}
    public override var hasConfigureSheet: Bool { false }
    public override var configureSheet: NSWindow? { nil }

    public override func layout() {
        super.layout()
        playerViewController?.view.frame = bounds
    }

    @objc private func loopVideo() {
        player?.seek(to: .zero) { [weak self] _ in
            DispatchQueue.main.async {
                self?.player?.play()
            }
        }
    }

    private func videoURL() -> URL? {
        let screensaverFile = sharedDir.appendingPathComponent("screensaverVideo.mp4")
        if FileManager.default.fileExists(atPath: screensaverFile.path) {
            return screensaverFile
        }

        let liveFile = sharedDir.appendingPathComponent("currentVideo.mp4")
        if FileManager.default.fileExists(atPath: liveFile.path) {
            return liveFile
        }

        let txt = sharedDir.appendingPathComponent("selectedVideoURL.txt")
        guard let raw = try? String(contentsOf: txt, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return nil
        }

        if let url = URL(string: raw),
           url.isFileURL,
           FileManager.default.fileExists(atPath: url.path) {
            return url
        }

        let plain = URL(fileURLWithPath: raw)
        return FileManager.default.fileExists(atPath: plain.path) ? plain : nil
    }
}
