import SwiftUI

/// Twende brand palette — bold, vibrant, NO gradients.
/// Matches the mockups in client/ui/.
enum TwendeColor {
    static let primary = Color(red: 0.043, green: 0.231, blue: 0.325)        // #0B3B53
    static let primaryLight = Color(red: 0.090, green: 0.376, blue: 0.478)    // #17607A
    static let primaryDark = Color(red: 0.024, green: 0.149, blue: 0.204)     // #062634
    static let accent = Color(red: 0.039, green: 0.561, blue: 0.545)          // #0A8F8B

    static let background = Color(red: 0.988, green: 0.980, blue: 0.961)      // #FCFAF5
    static let surface = Color.white
    static let surfaceMuted = Color(red: 0.945, green: 0.957, blue: 0.949)    // #F1F4F2
    static let surfaceSubtle = Color(red: 0.969, green: 0.973, blue: 0.961)   // #F7F8F5

    static let textPrimary = Color(red: 0.039, green: 0.102, blue: 0.180)     // #0A1A2E
    static let textSecondary = Color(red: 0.290, green: 0.333, blue: 0.400)   // #4A5566
    static let textTertiary = Color(red: 0.541, green: 0.580, blue: 0.651)    // #8A94A6
    static let textInverse = Color.white

    static let border = Color(red: 0.906, green: 0.890, blue: 0.859)          // #E7E3DB
    static let borderSubtle = Color(red: 0.937, green: 0.922, blue: 0.886)    // #EFEBE2

    static let success = Color(red: 0.106, green: 0.498, blue: 0.290)         // #1B7F4A
    static let successBg = Color(red: 0.890, green: 0.953, blue: 0.918)       // #E3F3EA
    static let warning = Color(red: 0.788, green: 0.478, blue: 0.106)         // #C97A1B
    static let warningBg = Color(red: 0.988, green: 0.937, blue: 0.851)       // #FCEFD9
    static let danger = Color(red: 0.706, green: 0.137, blue: 0.094)          // #B42318
    static let dangerBg = Color(red: 0.984, green: 0.910, blue: 0.902)        // #FBE8E6

    static let star = Color(red: 0.843, green: 0.545, blue: 0.082)            // #D78B15

    static let shadow = Color(red: 0.043, green: 0.141, blue: 0.278).opacity(0.10)
}
