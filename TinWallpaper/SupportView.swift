import SwiftUI
import AppKit

struct SupportView: View {

    @EnvironmentObject private var updateManager: UpdateManager
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

            Toggle("Auto-check for updates", isOn: $updateManager.autoCheckEnabled)
                .toggleStyle(.switch)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.20, green: 0.34, blue: 0.26))

            Button("Check for Updates") {
                Task {
                    await updateManager.checkForUpdates(manual: true)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(updateManager.isChecking)
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
