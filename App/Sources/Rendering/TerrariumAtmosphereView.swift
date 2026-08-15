import SwiftUI
import TerrariumCore

struct WaterGlintsView: View {
    let droplets: [TerrariumLayout.Droplet]
    let reduceMotion: Bool
    @State private var shimmering = false

    var body: some View {
        GeometryReader { geometry in
            ForEach(Array(droplets.prefix(8).enumerated()), id: \.offset) { index, droplet in
                DropletGlint(isSparkle: index.isMultiple(of: 5), glint: droplet.glint)
                    .frame(
                        width: 5 + CGFloat(droplet.size) * 110,
                        height: 8 + CGFloat(droplet.size) * 150
                    )
                    .position(
                        x: geometry.size.width * CGFloat(0.5 + droplet.xRatio * 0.31),
                        y: geometry.size.height * CGFloat(0.14 + droplet.yRatio * 0.69)
                    )
                    .opacity(reduceMotion ? 0.48 : (shimmering == index.isMultiple(of: 2) ? 0.72 : 0.20))
                    .animation(
                        reduceMotion
                            ? nil
                            : .easeInOut(duration: 1.1 + Double(index % 5) * 0.17)
                                .repeatForever(autoreverses: true),
                        value: shimmering
                    )
            }
        }
        .onAppear { shimmering = true }
        .accessibilityHidden(true)
    }
}

private struct DropletGlint: View {
    let isSparkle: Bool
    let glint: Float

    var body: some View {
        if isSparkle {
            Image(systemName: "sparkle")
                .font(.system(size: 9, weight: .light))
                .foregroundStyle(.white.opacity(0.68))
                .shadow(color: .cyan.opacity(0.58), radius: 4)
        } else {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.56 + Double(glint) * 0.14),
                            .cyan.opacity(0.11),
                            .white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: 2.4, height: 2.4)
                        .padding(2)
                }
                .shadow(color: .cyan.opacity(0.28), radius: 3)
        }
    }
}

struct RomanticMotesView: View {
    let reduceMotion: Bool
    @State private var floating = false

    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<6, id: \.self) { index in
                let ratio = CGFloat(index) / 5
                Circle()
                    .fill(index.isMultiple(of: 3) ? Color.cyan : Color.yellow)
                    .frame(width: 1.5 + CGFloat(index % 4), height: 1.5 + CGFloat(index % 4))
                    .blur(radius: index.isMultiple(of: 2) ? 0.8 : 1.8)
                    .shadow(
                        color: (index.isMultiple(of: 3) ? Color.cyan : Color.yellow).opacity(0.55),
                        radius: 4
                    )
                    .position(
                        x: geometry.size.width * (0.22 + ratio * 0.56),
                        y: geometry.size.height * (0.26 + CGFloat((index * 7) % 11) / 20)
                    )
                    .offset(
                        x: reduceMotion ? 0 : (floating ? CGFloat((index % 3) - 1) * 7 : 0),
                        y: reduceMotion ? 0 : (floating ? -8 - CGFloat(index % 4) * 2 : 3)
                    )
                    .opacity(floating || reduceMotion ? 0.14 + Double(index % 3) * 0.06 : 0.04)
                    .animation(
                        reduceMotion
                            ? nil
                            : .easeInOut(duration: 2.8 + Double(index % 5) * 0.42)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.09),
                        value: floating
                    )
            }
        }
        .onAppear { floating = true }
        .accessibilityHidden(true)
    }
}
