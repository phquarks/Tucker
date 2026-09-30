import SwiftUI

struct AboutSettingsView: View {
    private let brandBackground = Color(red: 0.035, green: 0.039, blue: 0.059)
    private let brandAccent = Color(red: 0.72, green: 0.61, blue: 1.0)
    private let developerWebsite = URL(string: "https://quarks.kz")!

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                details
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var hero: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 26) {
                avatar(size: 126)
                identity(alignment: .leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)

            VStack(spacing: 18) {
                avatar(size: 108)
                identity(alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
        }
        .frame(maxWidth: .infinity)
        .background(brandBackground)
    }

    private func avatar(size: CGFloat) -> some View {
        Image("AboutAvatar")
            .resizable()
            .interpolation(.high)
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(brandAccent.opacity(0.32), lineWidth: 1)
            }
            .shadow(color: brandAccent.opacity(0.2), radius: 18, y: 8)
            .accessibilityHidden(true)
    }

    private func identity(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 9) {
            Text("Tucker")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Keep your menu bar tidy.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.68))
                .multilineTextAlignment(alignment == .center ? .center : .leading)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 22) {
            Grid(alignment: .leading, horizontalSpacing: 30, verticalSpacing: 13) {
                metadataRow(label: "Developer", value: "Quarks")
                metadataRow(label: "Requires", value: "macOS 15 or later")
            }
            .font(.callout)

            Link(destination: developerWebsite) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Visit Developer Website")
                            .font(.callout.weight(.semibold))
                        Text("quarks.kz")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 16)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .background(brandAccent.opacity(0.11), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(brandAccent.opacity(0.28), lineWidth: 1)
            }
            .help("Open https://quarks.kz")

            Divider()

            Text("Copyright © Quarks.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 560, alignment: .leading)
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    private func metadataRow(label: String, value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.trailing)

            Text(value)
                .textSelection(.enabled)
        }
    }
}
