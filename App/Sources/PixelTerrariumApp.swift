import SwiftUI
import TerrariumCore

@main
struct PixelTerrariumApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

private struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "tree.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.green)
                Text("Pixel Terrarium")
                    .font(.largeTitle.bold())
                Text(TerrariumCore.isReady ? "準備ができました" : "準備中")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
