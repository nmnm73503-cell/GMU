import SwiftUI

struct GlassCard<Content: View>: View {
    var padding: CGFloat = Theme.padding
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(.ultraThinMaterial)
            .background(Theme.cream.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Theme.navy.opacity(0.06), radius: 16, y: 8)
    }
}

struct LuxuryButton: View {
    let title: String
    var style: Style = .primary
    var action: () -> Void

    enum Style { case primary, secondary, destructive }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(foreground)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        switch style {
        case .primary: return Theme.cream
        case .secondary: return Theme.navy
        case .destructive: return .white
        }
    }

    private var background: Color {
        switch style {
        case .primary: return Theme.navy
        case .secondary: return Theme.gold.opacity(0.25)
        case .destructive: return .red.opacity(0.85)
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    var accent: Color = Theme.gold

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.navy)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(accent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.titleFont)
                .foregroundStyle(Theme.navy)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.gold)
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Theme.gold)
            Text(title)
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.navy)
            Text(message)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
