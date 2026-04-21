import Foundation

// Temporary — remove once everything works.
struct DiagnosticHelper {
    static func run() {
        let sharedDir = URL(fileURLWithPath: "/Users/Shared/TinWallpaper")
        let videoFile = sharedDir.appendingPathComponent("currentVideo.mp4")
        let txtFile   = sharedDir.appendingPathComponent("selectedVideoURL.txt")

        print("=== TinWallpaper Diagnostics ===")

        let dirExists = FileManager.default.fileExists(atPath: sharedDir.path)
        print("Shared dir exists: \(dirExists)")

        if FileManager.default.fileExists(atPath: videoFile.path) {
            let attrs = try? FileManager.default.attributesOfItem(atPath: videoFile.path)
            let size = (attrs?[.size] as? Int64) ?? 0
            let perms = (attrs?[.posixPermissions] as? Int) ?? 0
            let readable = FileManager.default.isReadableFile(atPath: videoFile.path)
            print("currentVideo.mp4: ✅ \(size / 1_000_000) MB | perms: \(String(perms, radix: 8)) | readable: \(readable)")
        } else {
            print("currentVideo.mp4: ❌ NOT FOUND")
        }

        if FileManager.default.fileExists(atPath: txtFile.path) {
            let contents = (try? String(contentsOf: txtFile, encoding: .utf8)) ?? "(unreadable)"
            print("selectedVideoURL.txt: \(contents.trimmingCharacters(in: .whitespacesAndNewlines))")
        } else {
            print("selectedVideoURL.txt: ❌ NOT FOUND")
        }

        print("UserDefaults savedVideoURL: \(UserDefaults.standard.string(forKey: "savedVideoURL") ?? "(not set)")")
        print("================================")
    }
}
