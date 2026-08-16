import SwiftUI
import TerrariumCore
import UIKit

struct TerrariumWidgetArtworkView: View {
    let snapshot: TerrariumWidgetSnapshot
    let artworkData: Data?

    var body: some View {
        Group {
            if let artworkData,
               let image = UIImage(data: artworkData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack(spacing: 5) {
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                    Text("テラリウムを準備中")
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(.secondary)
            }
        }
        .aspectRatio(0.82, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
