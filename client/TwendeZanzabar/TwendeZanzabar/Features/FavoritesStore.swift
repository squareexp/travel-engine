import Combine
import Foundation

/// Persistent set of favorited listing ids.
@MainActor
final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    private let key = "com.twende.favorites"
    @Published private(set) var ids: Set<String>

    init() {
        if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
            self.ids = Set(saved)
        } else {
            self.ids = []
        }
    }

    func contains(_ id: String) -> Bool { ids.contains(id) }

    func toggle(_ id: String) {
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}
