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

#Preview {
    VStack(spacing: 12) {
        RemoteImage(url: "https://images.unsplash.com/photo-1571401835393-8c5f35328320?w=600")
            .frame(width: 300, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        RemoteImage(url: nil)
            .frame(width: 300, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .padding()
}
