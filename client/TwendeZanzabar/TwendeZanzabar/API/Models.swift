import Foundation

struct UserInfo: Codable, Identifiable {
    let id: String
    let email: String
    let full_name: String
    let role: String
    let phone: String?
}

struct AuthResponse: Codable {
    let access_token: String
    let refresh_token: String
    let user: UserInfo
}

struct Destination: Codable, Identifiable {
    let id: String
    let name: String
    let country: String
    let region: String?
    let description: String?
    let image_urls: [String]?
}

struct DestinationList: Codable {
    let data: [Destination]
    let total: Int?
}

struct Listing: Codable, Identifiable {
    let id: String
    let title: String
    let listing_type: String
    let base_price: AnyNumber
    let currency: String
    let description: String?
    let destination_name: String?
    let average_rating: AnyNumber?
    let review_count: Int?
    let capacity: Int?
    let duration_hours: Int?
    let inclusions: [String]?

    var price: Double { base_price.value }
    var rating: Double? { average_rating?.value }
    var formattedPrice: String { "$\(Int(price))" }
}

struct ListingList: Codable {
    let data: [Listing]
    let total: Int?
}

struct Booking: Codable, Identifiable {
    let id: String
    let listing_title: String?
    let status: String
    let travel_date: String?
    let guests: Int
    let total_amount: AnyNumber
    let currency: String
}

struct BookingList: Codable {
    let data: [Booking]
    let total: Int?
}

/// Server returns numbers as either JSON numbers or strings (BigDecimal serialization).
struct AnyNumber: Codable {
    let value: Double
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let d = try? c.decode(Double.self) { self.value = d; return }
        if let i = try? c.decode(Int.self) { self.value = Double(i); return }
        if let s = try? c.decode(String.self), let d = Double(s) { self.value = d; return }
        self.value = 0
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(value)
    }
}
