import Foundation

@MainActor
final class CatalogRepository {
    static let shared = CatalogRepository()

    func destinations() async throws -> [Destination] {
        let resp: DestinationList = try await APIClient.shared.get("destinations?limit=20", auth: true)
        return resp.data
    }

    func featuredListings() async throws -> [Listing] {
        let resp: ListingList = try await APIClient.shared.get("listings?limit=12", auth: true)
        return resp.data
    }

    func search(type: String?, text: String?) async throws -> [Listing] {
        var query = "listings?limit=30"
        if let t = type, !t.isEmpty { query += "&type=\(t)" }
        if let s = text, !s.isEmpty {
            let encoded = s.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed) ?? s
            query += "&search=\(encoded)"
        }
        let resp: ListingList = try await APIClient.shared.get(query, auth: true)
        return resp.data
    }

    func listing(id: String) async throws -> Listing {
        try await APIClient.shared.get("listings/\(id)", auth: true)
    }
}

@MainActor
final class BookingsRepository {
    static let shared = BookingsRepository()

    func myBookings() async throws -> [Booking] {
        let resp: BookingList = try await APIClient.shared.get("bookings", auth: true)
        return resp.data
    }

    struct CreateBookingBody: Encodable {
        let listing_id: String
        let travel_date: String
        let guests: Int
    }

    func createBooking(listingId: String, travelDate: String, guests: Int) async throws -> Booking {
        let body = CreateBookingBody(
            listing_id: listingId, travel_date: travelDate, guests: guests
        )
        return try await APIClient.shared.post("bookings", body: body, auth: true)
    }
}

@MainActor
final class TransportRepository {
    static let shared = TransportRepository()

    func listCars() async throws -> [[String: Any]] {
        // Generic JSON decode since Pistoni's car shape is opaque to us.
        guard let url = URL(string: "transport/cars", relativeTo: APIConfig.backendBaseURL) else {
            return []
        }
        var req = URLRequest(url: url)
        if let token = AuthStorage.shared.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return []
        }
        if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let list = dict["data"] as? [[String: Any]] {
            return list
        }
        if let list = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return list
        }
        return []
    }
}
