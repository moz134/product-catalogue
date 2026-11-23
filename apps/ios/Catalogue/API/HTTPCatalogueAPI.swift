import Foundation

/// The only type in the app that knows the API's URLs and wire format.
struct HTTPCatalogueAPI: CatalogueAPI {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func featuredProducts() async throws(APIError) -> [Product] {
        try await get(ItemsResponse<Product>.self, path: ["products", "featured"]).items
    }

    func categories() async throws(APIError) -> [ProductCategory] {
        try await get(ItemsResponse<ProductCategory>.self, path: ["categories"]).items
    }

    func categoryPage(slug: String) async throws(APIError) -> CategoryPage {
        try await get(CategoryPage.self, path: ["categories", slug, "products"])
    }

    func searchProducts(term: String) async throws(APIError) -> [Product] {
        try await get(ItemsResponse<Product>.self, path: ["products"], query: [URLQueryItem(name: "search", value: term)]).items
    }

    func product(id: String) async throws(APIError) -> Product {
        try await get(Product.self, path: ["products", id])
    }

    func submitEnquiry(_ enquiry: EnquiryRequest) async throws(APIError) -> EnquiryResponse {
        var request = URLRequest(url: url(path: ["enquiries"]))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(enquiry)
        } catch {
            throw .invalidResponse
        }
        return try await send(request, decoding: EnquiryResponse.self)
    }

    // MARK: - Plumbing

    private func get<T: Decodable>(_ type: T.Type, path: [String], query: [URLQueryItem] = []) async throws(APIError) -> T {
        try await send(URLRequest(url: url(path: path, query: query)), decoding: type)
    }

    /// Each path segment is percent-encoded individually (including "/"), so ids and slugs
    /// can't change the route.
    func url(path: [String], query: [URLQueryItem] = []) -> URL {
        var url = baseURL
        for segment in path {
            url.append(component: segment)
        }
        if !query.isEmpty {
            url.append(queryItems: query)
        }
        return url
    }

    private func send<T: Decodable>(_ request: URLRequest, decoding type: T.Type) async throws(APIError) -> T {
        var request = request
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw .network
        }
        guard let http = response as? HTTPURLResponse else { throw .invalidResponse }

        guard (200..<300).contains(http.statusCode) else {
            throw Self.error(status: http.statusCode, body: data)
        }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw .invalidResponse
        }
    }

    static func error(status: Int, body: Data) -> APIError {
        if status == 404 { return .notFound }
        guard let parsed = try? JSONDecoder().decode(APIErrorResponse.self, from: body) else {
            return .server(status: status, code: "UNKNOWN", message: "Something went wrong. Please try again.")
        }
        if parsed.error.code == "VALIDATION_ERROR" {
            return .validation(message: parsed.error.message, fields: parsed.error.fields ?? [:])
        }
        return .server(status: status, code: parsed.error.code, message: parsed.error.message)
    }
}
