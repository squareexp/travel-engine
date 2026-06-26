import SwiftUI

enum TwendeTypography {
    static let wordmark = Font.system(.title, design: .serif).weight(.bold)
    static let h1 = Font.system(size: 28, weight: .bold, design: .default)
    static let h2 = Font.system(size: 22, weight: .bold, design: .default)
    static let h3 = Font.system(size: 18, weight: .bold, design: .default)
    static let title = Font.system(size: 16, weight: .semibold, design: .default)
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let body = Font.system(size: 14, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let button = Font.system(size: 15, weight: .semibold, design: .default)
    static let label = Font.system(size: 13, weight: .medium, design: .default)
}

enum TwendeSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32

    static let radiusSm: CGFloat = 10
    static let radiusMd: CGFloat = 14
    static let radiusLg: CGFloat = 20
    static let radiusXl: CGFloat = 28
    static let radiusPill: CGFloat = 999
}
