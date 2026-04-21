import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {

    @StateObject private var manager = WallpaperManager()
    @State private var selectedMode: WallpaperManager.OutputMode = .liveWallpaper

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.83, green: 0.94, blue: 0.86),
                    Color(red: 0.74, green: 0.89, blue: 0.80),
                    Color(red: 0.68, green: 0.84, blue: 0.76)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(red: 0.88, green: 0.97, blue: 0.90).opacity(0.8))
                .frame(width: 420, height: 420)
                .blur(radius: 20)
                .offset(x: -150, y: -170)

            Circle()
                .fill(Color(red: 0.66, green: 0.83, blue: 0.72).opacity(0.5))
                .frame(width: 380, height: 380)
                .blur(radius: 26)
                .offset(x: 180, y: 200)

            ContentBackgroundEffectView(material: .menu)
                .ignoresSafeArea()
                .opacity(0.48)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    modePicker
                    controls
                    applyActions
                    launchAtLoginToggle
                    recentsSection
                    ContentSupportView()
                }
                .padding(24)
            }
            .frame(width: 460)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color(red: 0.45, green: 0.66, blue: 0.54).opacity(0.30), lineWidth: 1)
            )
            .shadow(color: Color(red: 0.35, green: 0.54, blue: 0.43).opacity(0.25), radius: 20, x: 0, y: 14)
            .padding(22)
        }
        .onAppear {
            selectedMode = manager.outputMode
            runDiagnostics()
        }
        .onChange(of: selectedMode) { _, newMode in
            manager.changeOutputMode(to: newMode)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TIN WALLPAPER")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1.3)
                .foregroundStyle(Color(red: 0.26, green: 0.42, blue: 0.32).opacity(0.80))

            Text("Tinnie's Wallpaper Studio")
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.18, green: 0.32, blue: 0.24))

            HStack(spacing: 6) {
                Circle()
                    .fill(Color(red: 0.35, green: 0.72, blue: 0.45))
                    .frame(width: 7, height: 7)
                Text("RUNNING IN BACKGROUND")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.18, green: 0.32, blue: 0.24))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule(style: .continuous).fill(Color(red: 0.84, green: 0.95, blue: 0.80)))
            .overlay(Capsule(style: .continuous).stroke(Color(red: 0.57, green: 0.75, blue: 0.61), lineWidth: 1))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button(action: openVideo) {
                Label("Choose Video", systemImage: "film")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.44, green: 0.68, blue: 0.52))
            .controlSize(.large)

            Button(action: manager.togglePause) {
                Label(
                    manager.isPaused ? "Play" : "Pause",
                    systemImage: manager.isPaused ? "play.fill" : "pause.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(Color(red: 0.54, green: 0.73, blue: 0.58))
            .controlSize(.large)
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mode applies to next selected video")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.28, green: 0.44, blue: 0.34))

            Picker("Mode", selection: $selectedMode) {
                ForEach(WallpaperManager.OutputMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var applyActions: some View {
        HStack(spacing: 10) {
            Button("Apply as Live Wallpaper") {
                manager.applyCurrentToLiveWallpaper()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!manager.hasCurrentVideo)

            Button("Set as Screensaver Source") {
                manager.setCurrentForScreensaver()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!manager.hasCurrentVideo)
        }
    }

    private var launchAtLoginToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Launch at Login")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.18, green: 0.32, blue: 0.24))
                Text("Wallpaper restores automatically after reboot")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.30, green: 0.43, blue: 0.34).opacity(0.80))
            }
            Spacer()
            Toggle("", isOn: $manager.launchAtLogin)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(14)
        .background(Color.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(red: 0.61, green: 0.80, blue: 0.66).opacity(0.65), lineWidth: 1)
        )
    }

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Videos")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.20, green: 0.34, blue: 0.26))

            if manager.recentVideos.isEmpty {
                Text("No recent files yet — choose a video above to get started.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.30, green: 0.43, blue: 0.34).opacity(0.80))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(manager.recentVideos.prefix(5), id: \.self) { url in
                        Button {
                            manager.loadVideo(url: url)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundStyle(Color(red: 0.39, green: 0.62, blue: 0.47))
                                Text(url.lastPathComponent)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color(red: 0.18, green: 0.30, blue: 0.23))
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.90, green: 0.97, blue: 0.91).opacity(0.75), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 0.65, green: 0.82, blue: 0.69).opacity(0.55), lineWidth: 1)
        )
    }

    private func openVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie]
        panel.message = "Choose a video to use as your wallpaper"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            manager.loadVideo(url: url)
        }
    }

    private func runDiagnostics() {
        let sharedDir = URL(fileURLWithPath: "/Users/Shared/TinWallpaper")
        let txtFile = sharedDir.appendingPathComponent("selectedVideoURL.txt")
        let videoFile = sharedDir.appendingPathComponent("currentVideo.mp4")

        print("=== TinWallpaper Diagnostics ===")

        let dirExists = FileManager.default.fileExists(atPath: sharedDir.path)
        print("Shared dir exists: \(dirExists) -> \(sharedDir.path)")

        if FileManager.default.fileExists(atPath: txtFile.path) {
            let contents = (try? String(contentsOf: txtFile, encoding: .utf8)) ?? "(unreadable)"
            print("selectedVideoURL.txt: \(contents.trimmingCharacters(in: .whitespacesAndNewlines))")
        } else {
            print("selectedVideoURL.txt: NOT FOUND - no video has been selected yet")
        }

        let videoExists = FileManager.default.fileExists(atPath: videoFile.path)
        print("currentVideo.mp4 exists: \(videoExists)")
        if videoExists {
            let size = (try? FileManager.default.attributesOfItem(atPath: videoFile.path)[.size] as? Int64) ?? 0
            print("currentVideo.mp4 size: \(size / 1_000_000) MB")
        }

        let savedURL = UserDefaults.standard.string(forKey: "savedVideoURL") ?? "(not set)"
        print("UserDefaults savedVideoURL: \(savedURL)")
        print("================================")
    }
}

private struct ContentBackgroundEffectView: NSViewRepresentable {

    let material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.state = .active
        view.blendingMode = .behindWindow
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

private struct ContentSupportView: View {

    @State private var hover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Support Development")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.20, green: 0.34, blue: 0.26))

            Text("If you enjoy this app, support future updates and new features.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.29, green: 0.43, blue: 0.34).opacity(0.85))

            Button(action: openKoFi) {
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                    Text("Support on Ko-fi")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(Color(red: 0.15, green: 0.28, blue: 0.21))
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.78, green: 0.92, blue: 0.80),
                            Color(red: 0.67, green: 0.86, blue: 0.72)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(red: 0.49, green: 0.69, blue: 0.55), lineWidth: 1)
                )
                .scaleEffect(hover ? 1.02 : 1.0)
            }
            .buttonStyle(.plain)
            .onHover { hover = $0 }
            .animation(.easeOut(duration: 0.15), value: hover)

            Text("Thank you for supporting ongoing development.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.20, green: 0.34, blue: 0.26))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 0.61, green: 0.80, blue: 0.66).opacity(0.65), lineWidth: 1)
        )
    }

    private func openKoFi() {
        if let url = URL(string: "https://ko-fi.com/tinytinnie") {
            NSWorkspace.shared.open(url)
        }
    }
}
