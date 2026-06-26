import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case http(Int, String?)
    case decoding(Error)
    case transport(Error)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .http(let s, let body): return "HTTP \(s): \(body ?? "")"
        case .decoding(let e): return "Decoding: \(e.localizedDescription)"
        case .transport(let e): return e.localizedDescription
        case .unauthorized: return "Unauthorized"
        }
    }
}

@MainActor
final class APIClient {
    static let shared = APIClient()
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: cfg)
        self.decoder = JSONDecoder()
    }

    func get<T: Decodable>(_ path: String, auth: Bool = false) async throws -> T {
        try await request(method: "GET", path: path, body: nil as Empty?, auth: auth)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B, auth: Bool = false) async throws -> T {
        try await request(method: "POST", path: path, body: body, auth: auth)
    }

    private func request<T: Decodable, B: Encodable>(method: String, path: String, body: B?, auth: Bool) async throws -> T {
        guard let url = URL(string: path, relativeTo: APIConfig.backendBaseURL) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if auth, let token = AuthStorage.shared.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = try JSONEncoder().encode(body)
        }
        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                throw APIError.transport(URLError(.badServerResponse))
            }
            if http.statusCode == 401 {
                throw APIError.unauthorized
            }
            guard (200..<300).contains(http.statusCode) else {
                throw APIError.http(http.statusCode, String(data: data, encoding: .utf8))
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.transport(error)
        }
    }
}

struct Empty: Codable {}
