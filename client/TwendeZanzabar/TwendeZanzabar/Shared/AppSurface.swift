import SwiftUI

/// Shared continuous-corner surfaces. Nested elements derive their radius from
/// the inset, keeping the shape system visually concentric.
struct AppSurface<Content: View>: View {
    let radius: CGFloat
    let padding: CGFloat
    let emphasis: Bool
    @ViewBuilder var content: Content

    init(radius: CGFloat = TwendeSpacing.radiusLg, padding: CGFloat = TwendeSpacing.lg, emphasis: Bool = false, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.padding = padding
        self.emphasis = emphasis
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(emphasis ? TwendeColor.primary : TwendeColor.surface)
                    .shadow(color: .black.opacity(emphasis ? 0.12 : 0.055), radius: emphasis ? 18 : 10, y: 5)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(emphasis ? .white.opacity(0.14) : TwendeColor.borderSubtle, lineWidth: 1)
            )
    }
}

/// Adaptive Liquid Glass for the small set of high-value, interactive controls.
struct GlassAction<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26, *) {
            content
                .padding(TwendeSpacing.md)
                .glassEffect(.regular.tint(TwendeColor.accent).interactive(), in: .rect(cornerRadius: TwendeSpacing.radiusMd))
        } else {
            content
                .padding(TwendeSpacing.md)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TwendeSpacing.radiusMd, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: TwendeSpacing.radiusMd, style: .continuous).strokeBorder(.white.opacity(0.35)))
        }
    }
}

extension View {
    func twendeCard(radius: CGFloat = TwendeSpacing.radiusLg) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(TwendeColor.surface)
                .shadow(color: .black.opacity(0.055), radius: 10, y: 5)
        )
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(TwendeColor.borderSubtle))
    }
}
