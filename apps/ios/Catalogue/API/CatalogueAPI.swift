import Foundation

/// Views and view models depend only on this protocol, never on a concrete client.
protocol CatalogueAPI: Sendable {
    func featuredProducts() async throws(APIError) -> [Product]
    func categories() async throws(APIError) -> [ProductCategory]
    func categoryPage(slug: String) async throws(APIError) -> CategoryPage
    func searchProducts(term: String) async throws(APIError) -> [Product]
    func product(id: String) async throws(APIError) -> Product
    func submitEnquiry(_ enquiry: EnquiryRequest) async throws(APIError) -> EnquiryResponse
}
