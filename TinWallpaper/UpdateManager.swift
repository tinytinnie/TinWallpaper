import Foundation
import AppKit
import Combine

@MainActor
final class UpdateManager: ObservableObject {
    @Published var autoCheckEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoCheckEnabled, forKey: autoCheckEnabledKey)
        }
    }
    @Published private(set) var isChecking = false
    @Published private(set) var lastCheckDate: Date?

    private let autoCheckEnabledKey = "autoUpdateEnabled"
    private let lastCheckDateKey = "lastUpdateCheckDate"
    private let startupInterval: TimeInterval = 60 * 60 * 24
    private var timerCancellable: AnyCancellable?

    // Replace this with your own endpoint.
    // Supported JSON payloads:
    // 1) { "version": "1.2.3", "download_url": "https://..." }
    // 2) GitHub release API payload (tag_name/html_url)
    private let releaseInfoURLString = "https://api.github.com/repos/OWNER/REPO/releases/latest"

    init() {
        if UserDefaults.standard.object(forKey: autoCheckEnabledKey) == nil {
            autoCheckEnabled = true
        } else {
            autoCheckEnabled = UserDefaults.standard.bool(forKey: autoCheckEnabledKey)
        }

        if let timestamp = UserDefaults.standard.object(forKey: lastCheckDateKey) as? TimeInterval {
            lastCheckDate = Date(timeIntervalSince1970: timestamp)
        }

        startTimer()
    }

    func performStartupCheckIfNeeded() {
        guard autoCheckEnabled else { return }

        let now = Date()
        if let lastCheckDate, now.timeIntervalSince(lastCheckDate) < startupInterval {
            return
        }

        Task {
            await checkForUpdates(manual: false)
        }
    }

    func checkForUpdates(manual: Bool) async {
        guard !isChecking else { return }
        guard let releaseInfoURL else {
            if manual {
                showMessageAlert(title: "Updates", message: "Release feed URL is not configured yet.")
            }
            return
        }

        isChecking = true
        defer { isChecking = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: releaseInfoURL)
            let release = try parseRelease(from: data)

            lastCheckDate = Date()
            UserDefaults.standard.set(lastCheckDate?.timeIntervalSince1970, forKey: lastCheckDateKey)

            if isVersion(release.version, newerThan: currentVersion()) {
                showUpdateAlert(release: release)
            } else if manual {
                showMessageAlert(title: "Up to Date", message: "You already have the latest version installed.")
            }
        } catch {
            if manual {
                showMessageAlert(title: "Update Check Failed", message: error.localizedDescription)
            }
        }
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: startupInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard self.autoCheckEnabled else { return }

                Task {
                    await self.checkForUpdates(manual: false)
                }
            }
    }

    private var releaseInfoURL: URL? {
        if releaseInfoURLString.contains("OWNER/REPO") {
            return nil
        }
        return URL(string: releaseInfoURLString)
    }

    private func parseRelease(from data: Data) throws -> ReleaseInfo {
        if let github = try? JSONDecoder().decode(GitHubReleaseResponse.self, from: data) {
            let cleanVersion = github.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            return ReleaseInfo(version: cleanVersion, downloadURL: github.htmlURL)
        }

        let generic = try JSONDecoder().decode(GenericReleaseResponse.self, from: data)
        return ReleaseInfo(version: generic.version, downloadURL: generic.downloadURL)
    }

    private func currentVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    private func isVersion(_ lhs: String, newerThan rhs: String) -> Bool {
        lhs.compare(rhs, options: .numeric) == .orderedDescending
    }

    private func showUpdateAlert(release: ReleaseInfo) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Version \(release.version) is available."
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(release.downloadURL)
        }
    }

    private func showMessageAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

private struct ReleaseInfo {
    let version: String
    let downloadURL: URL
}

private struct GenericReleaseResponse: Decodable {
    let version: String
    let downloadURL: URL

    enum CodingKeys: String, CodingKey {
        case version
        case downloadURL = "download_url"
    }
}

private struct GitHubReleaseResponse: Decodable {
    let tagName: String
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}
