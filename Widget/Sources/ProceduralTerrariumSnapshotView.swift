import SwiftUI
import TerrariumCore

struct ProceduralTerrariumSnapshotView: View {
    let snapshot: TerrariumWidgetSnapshot

    private var layout: TerrariumLayout {
        TerrariumLayoutGenerator.generate(
            seed: snapshot.seed,
            growthPoints: snapshot.growthPoints,
            hydration: snapshot.hydration
        )
    }

    var body: some View {
        Canvas(opaque: false, colorMode: .extendedLinear) { context, size in
            let geometry = SnapshotGeometry(size: size)
            drawGlassFill(in: &context, geometry: geometry)
            drawGround(in: &context, geometry: geometry)
            drawMoss(in: &context, geometry: geometry)
            drawBranch(in: &context, geometry: geometry)
            drawStones(in: &context, geometry: geometry)
            drawFern(in: &context, geometry: geometry)
            drawDroplets(in: &context, geometry: geometry)
            drawAtmosphere(in: &context, geometry: geometry)
            drawHardware(in: &context, geometry: geometry)
            drawGlassOutline(in: &context, geometry: geometry)
        }
        .aspectRatio(0.82, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

private extension ProceduralTerrariumSnapshotView {
    private func drawGlassFill(in context: inout GraphicsContext, geometry: SnapshotGeometry) {
        context.fill(
            geometry.clochePath,
            with: .linearGradient(
                Gradient(colors: [.cyan.opacity(0.12), .white.opacity(0.025)]),
                startPoint: CGPoint(x: geometry.centerX - geometry.jarWidth / 2, y: 0),
                endPoint: CGPoint(x: geometry.centerX + geometry.jarWidth / 2, y: geometry.baseY)
            )
        )
    }

    private func drawGround(in context: inout GraphicsContext, geometry: SnapshotGeometry) {
        let drainage = CGRect(
            x: geometry.centerX - geometry.jarWidth * 0.43,
            y: geometry.groundY + geometry.size.height * 0.015,
            width: geometry.jarWidth * 0.86,
            height: geometry.size.height * 0.075
        )
        context.fill(Path(ellipseIn: drainage), with: .color(Color(red: 0.16, green: 0.15, blue: 0.12)))

        let charcoal = drainage.offsetBy(dx: 0, dy: -geometry.size.height * 0.028)
        context.fill(Path(ellipseIn: charcoal), with: .color(Color(red: 0.035, green: 0.04, blue: 0.03)))

        var soil = Path()
        let groundLeft = CGPoint(
            x: geometry.centerX - geometry.jarWidth * 0.43,
            y: geometry.groundY + geometry.size.height * 0.025
        )
        let groundRight = CGPoint(
            x: geometry.centerX + geometry.jarWidth * 0.43,
            y: geometry.groundY + geometry.size.height * 0.025
        )
        soil.move(to: groundLeft)
        soil.addCurve(
            to: groundRight,
            control1: CGPoint(
                x: geometry.centerX - geometry.jarWidth * 0.22,
                y: geometry.groundY - geometry.size.height * 0.15
            ),
            control2: CGPoint(
                x: geometry.centerX + geometry.jarWidth * 0.12,
                y: geometry.groundY - geometry.size.height * 0.11
            )
        )
        soil.addLine(to: CGPoint(
            x: geometry.centerX + geometry.jarWidth * 0.40,
            y: geometry.groundY + geometry.size.height * 0.065
        ))
        soil.addLine(to: CGPoint(
            x: geometry.centerX - geometry.jarWidth * 0.40,
            y: geometry.groundY + geometry.size.height * 0.065
        ))
        soil.closeSubpath()
        context.fill(soil, with: .linearGradient(
            Gradient(colors: [
                Color(red: 0.20, green: 0.12, blue: 0.055),
                Color(red: 0.07, green: 0.04, blue: 0.02)
            ]),
            startPoint: CGPoint(x: geometry.centerX, y: geometry.groundY - geometry.size.height * 0.14),
            endPoint: CGPoint(x: geometry.centerX, y: geometry.groundY + geometry.size.height * 0.06)
        ))
    }

    private func drawMoss(in context: inout GraphicsContext, geometry: SnapshotGeometry) {
        let hydrated = snapshot.hydration >= 40
        let colors: [Color] = hydrated
            ? [
                Color(red: 0.10, green: 0.34, blue: 0.07),
                Color(red: 0.23, green: 0.52, blue: 0.08),
                Color(red: 0.48, green: 0.67, blue: 0.08)
            ]
            : [
                Color(red: 0.27, green: 0.31, blue: 0.08),
                Color(red: 0.38, green: 0.39, blue: 0.09),
                Color(red: 0.48, green: 0.44, blue: 0.10)
            ]
        let sortedMounds = layout.mossMounds.sorted { $0.zPosition > $1.zPosition }
        for mound in sortedMounds {
            let center = geometry.project(xPosition: mound.xPosition, zPosition: mound.zPosition)
            let width = CGFloat(mound.radius) * geometry.jarWidth * 0.57
            let height = CGFloat(mound.height) * geometry.size.height * 0.55
            let rect = CGRect(
                x: center.x - width / 2,
                y: center.y - height,
                width: width,
                height: height * 1.35
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    Gradient(colors: [
                        colors[mound.tone].opacity(1),
                        colors[mound.tone].opacity(0.78),
                        Color(red: 0.025, green: 0.09, blue: 0.025)
                    ]),
                    center: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.minY + rect.height * 0.24),
                    startRadius: 0,
                    endRadius: max(rect.width, rect.height) * 0.68
                )
            )
            drawMossDetail(in: &context, rect: rect, tone: mound.tone, hydrated: hydrated)
        }
    }

    private func drawMossDetail(
        in context: inout GraphicsContext,
        rect: CGRect,
        tone: Int,
        hydrated: Bool
    ) {
        for index in 0..<5 {
            let grain = max(0.9, rect.width * (0.045 + CGFloat(index % 2) * 0.012))
            let mossGrain = CGRect(
                x: rect.minX + rect.width * (0.16 + CGFloat((index * 7) % 11) / 15),
                y: rect.minY + rect.height * (0.12 + CGFloat((index * 5) % 9) / 16),
                width: grain,
                height: grain * 0.76
            )
            context.fill(
                Path(ellipseIn: mossGrain),
                with: .color(.white.opacity(hydrated ? 0.22 : 0.09))
            )
        }
        guard tone == 2 else { return }

        let highlight = CGRect(
            x: rect.minX + rect.width * 0.24,
            y: rect.minY + rect.height * 0.18,
            width: max(1.5, rect.width * 0.16),
            height: max(1.5, rect.width * 0.12)
        )
        context.fill(Path(ellipseIn: highlight), with: .color(.yellow.opacity(0.52)))
    }

    private func drawBranch(in context: inout GraphicsContext, geometry: SnapshotGeometry) {
        var path = Path()
        path.move(to: geometry.project(xPosition: -0.54, zPosition: 0.18))
        path.addQuadCurve(
            to: geometry.project(xPosition: 0.58, zPosition: -0.06),
            control: CGPoint(
                x: geometry.centerX - geometry.jarWidth * 0.03,
                y: geometry.groundY - geometry.size.height * 0.075
            )
        )
        context.stroke(
            path,
            with: .color(Color(red: 0.36, green: 0.17, blue: 0.045)),
            style: StrokeStyle(lineWidth: max(2, geometry.size.width * 0.034), lineCap: .round)
        )
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [.orange.opacity(0.56), .clear]),
                startPoint: geometry.project(xPosition: -0.54, zPosition: 0.18),
                endPoint: geometry.project(xPosition: 0.44, zPosition: -0.04)
            ),
            style: StrokeStyle(lineWidth: max(0.6, geometry.size.width * 0.007), lineCap: .round)
        )
    }

    private func drawStones(in context: inout GraphicsContext, geometry: SnapshotGeometry) {
        let colors = [
            Color(red: 0.52, green: 0.50, blue: 0.40),
            Color(red: 0.38, green: 0.42, blue: 0.38),
            Color(red: 0.61, green: 0.56, blue: 0.45)
        ]
        for stone in layout.stones {
            let center = geometry.project(xPosition: stone.xPosition, zPosition: stone.zPosition)
            let diameter = CGFloat(stone.radius) * geometry.jarWidth * 0.62
            let rect = CGRect(
                x: center.x - diameter / 2,
                y: center.y - diameter * 0.70,
                width: diameter,
                height: diameter * 0.78
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .linearGradient(
                    Gradient(colors: [
                        .white.opacity(snapshot.hydration >= 40 ? 0.66 : 0.36),
                        colors[stone.tone],
                        .black.opacity(0.72)
                    ]),
                    startPoint: CGPoint(x: rect.minX, y: rect.minY),
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                )
            )
        }
    }

    private func drawFern(in context: inout GraphicsContext, geometry: SnapshotGeometry) {
        let hydrated = snapshot.hydration >= 40
        let stemColor = hydrated ? Color(red: 0.48, green: 0.72, blue: 0.10) : Color.olive
        let anchor = CGPoint(x: geometry.centerX, y: geometry.groundY - geometry.size.height * 0.03)

        if layout.fernFronds.isEmpty {
            context.fill(
                Path(ellipseIn: CGRect(x: anchor.x - 2.5, y: anchor.y - 3, width: 5, height: 4)),
                with: .color(.brown)
            )
            return
        }

        for frond in layout.fernFronds {
            let height = CGFloat(frond.height) * geometry.size.height * 0.39
            let tip = CGPoint(
                x: anchor.x + CGFloat(sin(frond.angle)) * height * 0.43,
                y: anchor.y - height
            )
            let control = CGPoint(
                x: anchor.x + CGFloat(sin(frond.angle)) * height * 0.20,
                y: anchor.y - height * 0.48
            )
            var stem = Path()
            stem.move(to: anchor)
            stem.addQuadCurve(to: tip, control: control)
            context.stroke(stem, with: .color(stemColor), lineWidth: max(1, geometry.size.width * 0.009))

            for level in 1...frond.leafletPairs {
                let progress = CGFloat(level) / CGFloat(frond.leafletPairs + 1)
                let center = quadraticPoint(from: anchor, control: control, to: tip, progress: progress)
                let leafLength = sin(progress * .pi) * geometry.size.width * 0.075 + 2
                for sign: CGFloat in [-1, 1] {
                    var leaf = Path()
                    leaf.move(to: center)
                    leaf.addLine(to: CGPoint(
                        x: center.x + sign * leafLength,
                        y: center.y - leafLength * 0.34
                    ))
                    context.stroke(leaf, with: .color(stemColor), lineWidth: max(1, geometry.size.width * 0.012))
                }
            }
        }
    }

    private func drawDroplets(in context: inout GraphicsContext, geometry: SnapshotGeometry) {
        guard snapshot.hydration >= 40 else { return }
        for droplet in layout.droplets.prefix(13) {
            let point = CGPoint(
                x: geometry.centerX + CGFloat(droplet.xRatio) * geometry.jarWidth * 0.42,
                y: geometry.size.height * CGFloat(0.14 + droplet.yRatio * 0.60)
            )
            let diameter = max(1.4, CGFloat(droplet.size) * geometry.size.width * 0.70)
            context.fill(
                Path(ellipseIn: CGRect(
                    x: point.x - diameter / 2,
                    y: point.y - diameter,
                    width: diameter,
                    height: diameter * 1.55
                )),
                with: .linearGradient(
                    Gradient(colors: [
                        .white.opacity(0.72 + Double(droplet.glint) * 0.25),
                        .cyan.opacity(0.24),
                        .clear
                    ]),
                    startPoint: CGPoint(x: point.x - diameter / 2, y: point.y - diameter),
                    endPoint: CGPoint(x: point.x + diameter / 2, y: point.y + diameter * 0.55)
                )
            )
        }
    }

    private func drawAtmosphere(in context: inout GraphicsContext, geometry: SnapshotGeometry) {
        let leftReflection = CGRect(
            x: geometry.centerX - geometry.jarWidth * 0.39,
            y: geometry.size.height * 0.23,
            width: max(1.2, geometry.size.width * 0.014),
            height: geometry.size.height * 0.36
        )
        context.fill(
            Path(roundedRect: leftReflection, cornerRadius: leftReflection.width),
            with: .linearGradient(
                Gradient(colors: [.clear, .white.opacity(0.62), .cyan.opacity(0.16), .clear]),
                startPoint: CGPoint(x: leftReflection.midX, y: leftReflection.minY),
                endPoint: CGPoint(x: leftReflection.midX, y: leftReflection.maxY)
            )
        )

        for index in 0..<4 {
            let diameter = max(1.2, geometry.size.width * (index.isMultiple(of: 3) ? 0.015 : 0.009))
            let point = CGPoint(
                x: geometry.centerX + geometry.jarWidth * CGFloat((index * 17) % 13 - 6) / 18,
                y: geometry.size.height * (0.25 + CGFloat((index * 11) % 9) / 23)
            )
            context.fill(
                Path(ellipseIn: CGRect(
                    x: point.x - diameter / 2,
                    y: point.y - diameter / 2,
                    width: diameter,
                    height: diameter
                )),
                with: .color((index.isMultiple(of: 3) ? Color.cyan : Color.yellow).opacity(0.42))
            )
        }
    }

    private func drawHardware(in context: inout GraphicsContext, geometry: SnapshotGeometry) {
        let darkMetal = Color(red: 0.055, green: 0.052, blue: 0.035)
        let bronze = Color(red: 0.31, green: 0.22, blue: 0.065)
        let baseRect = CGRect(
            x: geometry.centerX - geometry.jarWidth * 0.53,
            y: geometry.baseY,
            width: geometry.jarWidth * 1.06,
            height: geometry.size.height * 0.095
        )
        context.fill(Path(roundedRect: baseRect, cornerRadius: 4), with: .color(darkMetal))
        context.stroke(Path(roundedRect: baseRect, cornerRadius: 4), with: .color(bronze), lineWidth: 1.5)

        let collar = CGRect(
            x: geometry.centerX - geometry.jarWidth * 0.14,
            y: geometry.size.height * 0.045,
            width: geometry.jarWidth * 0.28,
            height: geometry.size.height * 0.055
        )
        context.fill(Path(roundedRect: collar, cornerRadius: 3), with: .color(darkMetal))
        let knob = CGRect(
            x: geometry.centerX - geometry.jarWidth * 0.06,
            y: geometry.size.height * 0.018,
            width: geometry.jarWidth * 0.12,
            height: geometry.size.height * 0.045
        )
        context.fill(Path(ellipseIn: knob), with: .color(darkMetal))
    }

    private func drawGlassOutline(in context: inout GraphicsContext, geometry: SnapshotGeometry) {
        context.stroke(
            geometry.clochePath,
            with: .linearGradient(
                Gradient(colors: [.white.opacity(0.82), .cyan.opacity(0.32), .white.opacity(0.55)]),
                startPoint: CGPoint(x: geometry.centerX - geometry.jarWidth / 2, y: 0),
                endPoint: CGPoint(x: geometry.centerX + geometry.jarWidth / 2, y: geometry.baseY)
            ),
            lineWidth: max(1.2, geometry.size.width * 0.012)
        )
    }

    private func quadraticPoint(
        from start: CGPoint,
        control: CGPoint,
        to end: CGPoint,
        progress: CGFloat
    ) -> CGPoint {
        let inverse = 1 - progress
        return CGPoint(
            x: inverse * inverse * start.x + 2 * inverse * progress * control.x + progress * progress * end.x,
            y: inverse * inverse * start.y + 2 * inverse * progress * control.y + progress * progress * end.y
        )
    }
}

private struct SnapshotGeometry {
    let size: CGSize
    let centerX: CGFloat
    let jarWidth: CGFloat
    let baseY: CGFloat
    let groundY: CGFloat
    let clochePath: Path

    init(size: CGSize) {
        self.size = size
        centerX = size.width / 2
        jarWidth = size.width * 0.78
        baseY = size.height * 0.80
        groundY = size.height * 0.73

        var path = Path()
        path.move(to: CGPoint(x: centerX - jarWidth * 0.46, y: baseY))
        path.addLine(to: CGPoint(x: centerX - jarWidth * 0.46, y: size.height * 0.30))
        path.addCurve(
            to: CGPoint(x: centerX - jarWidth * 0.16, y: size.height * 0.11),
            control1: CGPoint(x: centerX - jarWidth * 0.46, y: size.height * 0.18),
            control2: CGPoint(x: centerX - jarWidth * 0.30, y: size.height * 0.11)
        )
        path.addLine(to: CGPoint(x: centerX + jarWidth * 0.16, y: size.height * 0.11))
        path.addCurve(
            to: CGPoint(x: centerX + jarWidth * 0.46, y: size.height * 0.30),
            control1: CGPoint(x: centerX + jarWidth * 0.30, y: size.height * 0.11),
            control2: CGPoint(x: centerX + jarWidth * 0.46, y: size.height * 0.18)
        )
        path.addLine(to: CGPoint(x: centerX + jarWidth * 0.46, y: baseY))
        path.closeSubpath()
        clochePath = path
    }

    func project(xPosition: Float, zPosition: Float) -> CGPoint {
        CGPoint(
            x: centerX + CGFloat(xPosition) * jarWidth * 0.37,
            y: groundY - CGFloat(zPosition) * size.height * 0.085
        )
    }
}

private extension Color {
    static let olive = Color(red: 0.43, green: 0.45, blue: 0.10)
}
