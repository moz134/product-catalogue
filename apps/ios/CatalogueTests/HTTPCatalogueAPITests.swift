import Foundation
import Testing
@testable import Catalogue

struct HTTPCatalogueAPITests {
    private func json(_ object: Any) -> Data {
        try! JSONSerialization.data(withJSONObject: object)
    }

    @Test func featuredProductsDecodesTheItemsList() async throws {
        let fixture = try Fixtures.data("product-list.json")
        let api = StubURLProtocol.makeAPI { request in
            #expect(request.url?.path() == "/api/v1/products/featured")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            return (200, fixture)
        }

        let products = try await api.featuredProducts()

        #expect(products.map(\.id) == ["1", "9"])
    }

    @Test func searchSendsTheTermAsAnEncodedQueryParameter() async throws {
        let api = StubURLProtocol.makeAPI { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            #expect(components?.path == "/api/v1/products")
            #expect(components?.queryItems == [URLQueryItem(name: "search", value: "men's & co")])
            return (200, self.json(["items": []]))
        }

        let results = try await api.searchProducts(term: "men's & co")

        #expect(results.isEmpty)
    }

    @Test func pathSegmentsAreEncodedSoTheyCannotChangeTheRoute() {
        let api = HTTPCatalogueAPI(baseURL: URL(string: "http://localhost:3000/api/v1")!)

        let url = api.url(path: ["products", "../admin/x"])

        #expect(url.absoluteString == "http://localhost:3000/api/v1/products/..%2Fadmin%2Fx")
    }

    @Test func categoryPageHitsTheCategoryRoute() async throws {
        let fixture = try Fixtures.data("category-page.json")
        let api = StubURLProtocol.makeAPI { request in
            #expect(request.url?.path() == "/api/v1/categories/electronics/products")
            return (200, fixture)
        }

        let page = try await api.categoryPage(slug: "electronics")

        #expect(page.category.name == "Electronics")
        #expect(page.topRated.count == 1)
        #expect(page.others.count == 1)
    }

    @Test func notFoundMapsToNotFound() async {
        let api = StubURLProtocol.makeAPI { _ in (404, (try? Fixtures.data("error-not-found.json")) ?? Data()) }

        await #expect(throws: APIError.notFound) { try await api.product(id: "999") }
    }

    @Test func validationErrorsKeepFieldMessages() async throws {
        let fixture = try Fixtures.data("error-validation.json")
        let api = StubURLProtocol.makeAPI { _ in (400, fixture) }
        let enquiry = EnquiryRequest(productId: "1", name: "", email: "x", phone: nil, message: nil)

        await #expect(
            throws: APIError.validation(
                message: "The request is invalid",
                fields: ["name": ["Please enter your name"], "email": ["Please enter a valid email address"]]
            )
        ) { try await api.submitEnquiry(enquiry) }
    }

    @Test func serverErrorsCarryTheAPIsFriendlyMessage() async {
        let api = StubURLProtocol.makeAPI { _ in
            (502, self.json(["error": ["code": "UPSTREAM_UNAVAILABLE", "message": "Products are temporarily unavailable."]]))
        }

        await #expect(throws: APIError.server(status: 502, code: "UPSTREAM_UNAVAILABLE", message: "Products are temporarily unavailable.")) {
            try await api.featuredProducts()
        }
    }

    @Test func anUnreadableErrorBodyStillGivesAFriendlyError() async {
        let api = StubURLProtocol.makeAPI { _ in (500, Data("<html>oops</html>".utf8)) }

        do {
            _ = try await api.categories()
            Issue.record("Expected an error")
        } catch {
            #expect(error.userMessage == "Something went wrong. Please try again.")
        }
    }

    @Test func networkFailuresMapToNetwork() async {
        let api = StubURLProtocol.makeAPI { _ in throw URLError(.notConnectedToInternet) }

        await #expect(throws: APIError.network) { try await api.categories() }
    }

    @Test func aResponseThatBreaksTheContractIsInvalid() async {
        let api = StubURLProtocol.makeAPI { _ in (200, self.json(["items": [["id": 1]]])) }

        await #expect(throws: APIError.invalidResponse) { try await api.featuredProducts() }
    }

    @Test func submitEnquiryPostsJSONAndOmitsEmptyOptionalFields() async throws {
        let api = StubURLProtocol.makeAPI { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.path() == "/api/v1/enquiries")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            let body = try JSONSerialization.jsonObject(with: request.bodyData ?? Data()) as? [String: String]
            #expect(body == ["productId": "1", "name": "Ada", "email": "ada@example.com"])
            return (202, try Fixtures.data("enquiry-response.json"))
        }

        let response = try await api.submitEnquiry(
            EnquiryRequest(productId: "1", name: "Ada", email: "ada@example.com", phone: nil, message: nil)
        )

        #expect(response.reference == "0b9d6c1e-3f5a-4c1e-9b7a-2d4e6f8a1c3b")
    }
}
