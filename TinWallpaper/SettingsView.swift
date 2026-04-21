import SwiftUI
import AVFoundation
 
struct SettingsView: View {
    @ObservedObject var manager: WallpaperManager
    @State private var volume: Double = 0.0
 
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle.bold())
 
            VStack(alignment: .leading, spacing: 6) {
                Text("Volume")
                    .font(.headline)
                Slider(value: $volume, in: 0...1)
                    .onChange(of: volume) { _, newValue in
                        manager.player.volume = Float(newValue)
                    }
            }
 
            Divider()
 
            Button("Pause / Play") {
                manager.togglePause()
            }
            .buttonStyle(.bordered)
 
            Button("Restart Video") {
                manager.player.seek(to: .zero)
                manager.player.play()
            }
            .buttonStyle(.bordered)
 
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
