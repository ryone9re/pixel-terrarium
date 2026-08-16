import SwiftUI
import TerrariumCore

struct WaterGlintsView: View {
    let droplets: [TerrariumLayout.Droplet]
    let yaw: Float
    let reduceMotion: Bool
    @State private var shimmering = false

    var body: some View {
        GeometryReader { geometry in
            let frontDroplets = droplets.enumerated().filter {
                sin($0.element.azimuth - yaw) > 0.12
            }.prefix(10)
            ForEach(Array(frontDroplets), id: \.offset) { index, droplet in
                DropletGlint(isSparkle: index.isMultiple(of: 5), glint: droplet.glint)
                    .frame(
                        width: 4 + CGFloat(droplet.size) * 65,
                        height: 6 + CGFloat(droplet.size) * 100
                    )
                    .position(
                        x: geometry.size.width * CGFloat(
                            0.5 + cos(droplet.azimuth - yaw) * 0.31
                        ),
                        y: geometry.size.height * CGFloat(0.14 + droplet.yRatio * 0.69)
                    )
                    .opacity(reduceMotion ? 0.62 : (shimmering == index.isMultiple(of: 2) ? 0.82 : 0.50))
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
        CondensationLensShape()
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(0.45 + Double(glint) * 0.18),
                        .cyan.opacity(0.08),
                        .white.opacity(0.025)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                CondensationLensShape()
                    .stroke(.white.opacity(0.32), lineWidth: 0.45)
            }
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(.white.opacity(isSparkle ? 0.92 : 0.72))
                    .frame(width: isSparkle ? 1.5 : 1.0, height: isSparkle ? 0.65 : 0.5)
                    .padding(.top, 1.1)
                    .padding(.leading, 1.0)
                    .shadow(color: .white.opacity(isSparkle ? 0.48 : 0.18), radius: 1.1)
            }
            .shadow(color: .cyan.opacity(0.16), radius: 0.8)
    }
}

private struct CondensationLensShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.32),
            control2: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.82)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.82),
            control2: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.32)
        )
        return path
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
