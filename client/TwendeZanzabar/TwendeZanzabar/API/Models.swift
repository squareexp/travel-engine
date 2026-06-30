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
    init(_ value: Double) { self.value = value }
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

#if DEBUG
extension Listing {
    static var preview: Listing {
        Listing(id: "preview-1", title: "Nungwi Snorkeling Adventure", listing_type: "experience",
                base_price: AnyNumber(45), currency: "USD",
                description: "Explore the coral reefs of northern Zanzibar with certified local guides.",
                destination_name: "Nungwi, Zanzibar", average_rating: AnyNumber(4.8),
                review_count: 124, capacity: 12, duration_hours: 3,
                inclusions: ["Snorkel gear", "Boat transfer", "Guide", "Refreshments"])
    }
    static var previewSafari: Listing {
        Listing(id: "preview-2", title: "Selous Safari Day Trip", listing_type: "safari",
                base_price: AnyNumber(180), currency: "USD", description: nil,
                destination_name: "Selous Game Reserve", average_rating: AnyNumber(4.9),
                review_count: 87, capacity: 8, duration_hours: 8, inclusions: nil)
    }
}

extension Destination {
    static var preview: Destination {
        Destination(id: "d-preview", name: "Nungwi", country: "Tanzania",
                    region: "Zanzibar North", description: nil, image_urls: nil)
    }
    static var previewStone: Destination {
        Destination(id: "d-preview-2", name: "Stone Town", country: "Tanzania",
                    region: "Zanzibar West", description: nil, image_urls: nil)
    }
}

extension Booking {
    static var preview: Booking {
        Booking(id: "b-preview", listing_title: "Stone Town Walking Tour",
                status: "confirmed", travel_date: "2027-08-15", guests: 2,
                total_amount: AnyNumber(90), currency: "USD")
    }
    static var previewPending: Booking {
        Booking(id: "b-preview-2", listing_title: "Nungwi Snorkeling Adventure",
                status: "pending", travel_date: "2027-09-01", guests: 4,
                total_amount: AnyNumber(180), currency: "USD")
    }
}
#endif
