import SwiftUI
import TerrariumCore

struct TerrariumBackground: View {
    let period: DayPeriod

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            if period == .night {
                Canvas { context, size in
                    for index in 0..<18 {
                        let xPosition = CGFloat((index * 47) % 100) / 100 * size.width
                        let yPosition = CGFloat((index * 31) % 100) / 100 * size.height
                        context.fill(
                            Path(ellipseIn: CGRect(x: xPosition, y: yPosition, width: 3, height: 3)),
                            with: .color(.white.opacity(0.4))
                        )
                    }
                }
                .accessibilityHidden(true)
            }
        }
    }

    private var colors: [Color] {
        switch period {
        case .morning:
            [.skyBlue, .warmSun, .mossGreen.opacity(0.85)]
        case .daytime:
            [.mint.opacity(0.7), .white, .mossGreen.opacity(0.75)]
        case .evening:
            [.sunsetOrange, .purple.opacity(0.7), .deepForest]
        case .night:
            [.nightBlue, .deepForest, .black.opacity(0.9)]
        }
    }
}

extension Color {
    static let terrariumGreen = Color(red: 0.18, green: 0.61, blue: 0.35)
    static let mossGreen = Color(red: 0.22, green: 0.48, blue: 0.28)
    static let deepForest = Color(red: 0.04, green: 0.18, blue: 0.15)
    static let skyBlue = Color(red: 0.56, green: 0.78, blue: 0.88)
    static let warmSun = Color(red: 0.98, green: 0.77, blue: 0.47)
    static let sunsetOrange = Color(red: 0.92, green: 0.48, blue: 0.28)
    static let nightBlue = Color(red: 0.05, green: 0.12, blue: 0.30)
}
