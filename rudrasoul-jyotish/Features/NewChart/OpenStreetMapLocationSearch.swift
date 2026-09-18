import Foundation

/// Finds birth locations through OpenStreetMap's public Nominatim geocoding endpoint.
///
/// The lookup is deliberately user initiated so a person's birth-place text is never
/// transmitted until they ask to search. The endpoint supplies coordinates only; the
/// user remains responsible for confirming the applicable historical time-zone rule.
actor OpenStreetMapLocationSearch {
    struct Result: Identifiable, Hashable, Sendable {
        let displayName: String
        let latitude: Double
        let longitude: Double

        var id: String { "\(latitude),\(longitude),\(displayName)" }
    }

    enum SearchError: LocalizedError {
        case invalidQuery
        case unavailable

        var errorDescription: String? {
            switch self {
            case .invalidQuery:
                "Enter a city, town, or landmark to search."
            case .unavailable:
                "Location search is currently unavailable. You can enter coordinates manually."
            }
        }
    }

    private struct Response: Decodable {
        let displayName: String
        let latitude: String
        let longitude: String

        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case latitude = "lat"
            case longitude = "lon"
        }
    }

    func search(query: String) async throws -> [Result] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { throw SearchError.invalidQuery }

        var components = URLComponents(string: "https://nominatim.openstreetmap.org/search")
        components?.queryItems = [
            URLQueryItem(name: "format", value: "jsonv2"),
            URLQueryItem(name: "limit", value: "5"),
            URLQueryItem(name: "q", value: trimmedQuery),
        ]
        guard let url = components?.url else { throw SearchError.unavailable }

        var request = URLRequest(url: url)
        request.setValue("JyotishPro/1.0 (birth-location lookup)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ..< 300).contains(httpResponse.statusCode)
            else {
                throw SearchError.unavailable
            }

            return try JSONDecoder().decode([Response].self, from: data).compactMap { response in
                guard let latitude = Double(response.latitude), let longitude = Double(response.longitude) else {
                    return nil
                }
                return Result(displayName: response.displayName, latitude: latitude, longitude: longitude)
            }
        } catch let error as SearchError {
            throw error
        } catch {
            throw SearchError.unavailable
        }
    }
}
