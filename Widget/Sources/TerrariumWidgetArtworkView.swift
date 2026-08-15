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
                ProceduralTerrariumSnapshotView(snapshot: snapshot)
            }
        }
        .aspectRatio(0.82, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
