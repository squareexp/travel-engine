import SwiftUI

/// AsyncImage with a soft placeholder + graceful failure.
struct RemoteImage: View {
    let url: String?
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: url.flatMap(URL.init(string:))) { phase in
            switch phase {
            case .success(let img):
                img.resizable().aspectRatio(contentMode: contentMode)
            case .empty:
                placeholder
            case .failure:
                placeholder.overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(TwendeColor.textTertiary)
                )
            @unknown default:
                placeholder
            }
        }
    }

    private var placeholder: some View {
        TwendeColor.surfaceMuted
    }
}
