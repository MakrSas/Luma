import Foundation

/// Real, keyless network access backing `SearchWebTool`/`FetchURLTool` —
/// no API key, no mocked results.
enum WebSearchService {
    /// Wikipedia's public `opensearch` endpoint. No auth, no rate-limit key
    /// needed for light use; returns up to 5 real title+description results.
    static func search(query: String) async throws -> [String] {
        var components = URLComponents(string: "https://ru.wikipedia.org/w/api.php")!
        components.queryItems = [
            URLQueryItem(name: "action", value: "opensearch"),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "limit", value: "5"),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(OpenSearchResponse.self, from: data)
        guard !decoded.titles.isEmpty else { return [] }
        return zip(decoded.titles, decoded.descriptions).map { title, description in
            description.isEmpty ? title : "\(title): \(description)"
        }
    }

    /// Fetches a URL's raw text content (HTML tags stripped), truncated to
    /// keep it small enough to fit in the model's context window.
    static func fetchPageText(urlString: String) async throws -> String {
        guard let url = URL(string: urlString), let scheme = url.scheme,
              scheme == "http" || scheme == "https" else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        return String(html.strippingHTMLTags().prefix(4000))
    }
}

/// Wikipedia's `opensearch` response is a 4-element positional JSON array —
/// `[query, [titles], [descriptions], [urls]]` — not a keyed object.
private struct OpenSearchResponse: Decodable {
    let titles: [String]
    let descriptions: [String]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        _ = try container.decode(String.self)
        titles = try container.decode([String].self)
        descriptions = try container.decode([String].self)
    }
}

private extension String {
    func strippingHTMLTags() -> String {
        var result = ""
        var insideTag = false
        for char in self {
            if char == "<" { insideTag = true }
            else if char == ">" { insideTag = false }
            else if !insideTag { result.append(char) }
        }
        return result
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
