import SwiftUI

struct WaterDropsView: View {
    let reduceMotion: Bool
    @State private var isVisible = false

    var body: some View {
        ZStack {
            ForEach(0..<9, id: \.self) { index in
                Capsule()
                    .fill(.cyan.opacity(0.8))
                    .frame(width: 8, height: 16)
                    .offset(
                        x: CGFloat((index % 3) - 1) * 46,
                        y: reduceMotion ? 0 : (isVisible ? 80 : -100)
                    )
                    .opacity(isVisible ? 0 : 0.9)
                    .animation(
                        .easeIn(duration: 0.45).delay(Double(index) * 0.035),
                        value: isVisible
                    )
            }
        }
        .onAppear { isVisible = true }
        .accessibilityHidden(true)
    }
}
