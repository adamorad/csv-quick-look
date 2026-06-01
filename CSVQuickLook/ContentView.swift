import SwiftUI

struct ContentView: View {
    @AppStorage("maxRows") private var maxRows: Double = 100_000
    @AppStorage("autoDetectDelimiter") private var autoDetectDelimiter: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            settingsSection
            Divider()
            footerSection
        }
        .frame(minWidth: 480, minHeight: 380)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "tablecells")
                .font(.system(size: 52, weight: .thin))
                .foregroundColor(.accentColor)
                .padding(.top, 28)

            Text("CSV Quick Look")
                .font(.title2.weight(.semibold))

            HStack(spacing: 7) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                Text("Enable in System Settings › Extensions › Quick Look")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(Capsule())
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PREVIEW SETTINGS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            GroupBox {
                VStack(spacing: 12) {
                    Toggle("Auto-detect delimiter (comma, tab, semicolon, pipe)", isOn: $autoDetectDelimiter)
                        .help("Detects the separator used in the CSV file automatically")

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Max rows to display")
                            Spacer()
                            Text(formatCount(Int(maxRows)))
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $maxRows, in: 1_000...500_000, step: 1_000)
                    }
                }
                .padding(4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var footerSection: some View {
        HStack {
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.extensions?Quick Look") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.link)

            Spacer()

            Text("v1.0")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func formatCount(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return (f.string(from: NSNumber(value: n)) ?? "\(n)") + " rows"
    }
}
