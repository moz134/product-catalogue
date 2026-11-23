#if DEBUG
import Foundation

/// Offline data for UI tests (`-UITestStubAPI`) and previews. Debug builds only.
struct StubCatalogueAPI: CatalogueAPI {
    static let electronics = ProductCategory(slug: "electronics", name: "Electronics")
    static let jewelery = ProductCategory(slug: "jewelery", name: "Jewelery")

    static let products: [Product] = [
        make("1", "Laptop backpack", 109.95, electronics, rating: 3.9, image: "81fPKd-2AYL._AC_SL1500_t.png"),
        make("2", "SSD drive 1TB", 109.00, electronics, rating: 4.8, image: "61U7T1koQqL._AC_SX679_t.png"),
        make("3", "Portable hard drive 2TB", 64.00, electronics, rating: 3.3, image: "61IBBVJvSDL._AC_SY879_t.png"),
        make("4", "Monitor 27in", 599.00, electronics, rating: 4.5, image: "81QpkIctqPL._AC_SX679_t.png"),
        make("5", "Silver bracelet", 695.00, jewelery, rating: 4.6, image: "71pWzhdJNwL._AC_UL640_QL65_ML3_t.png"),
        make("6", "Gold ring", 168.00, jewelery, rating: 3.9, image: "61sbMiUnoGL._AC_UL640_QL65_ML3_t.png"),
    ]

    func featuredProducts() async throws(APIError) -> [Product] {
        Array(Self.products.prefix(5))
    }

    func categories() async throws(APIError) -> [ProductCategory] {
        [Self.electronics, Self.jewelery]
    }

    func categoryPage(slug: String) async throws(APIError) -> CategoryPage {
        guard let category = [Self.electronics, Self.jewelery].first(where: { $0.slug == slug }) else {
            throw .notFound
        }
        let inCategory = Self.products.filter { $0.category == category }
        return CategoryPage(category: category, topRated: Array(inCategory.prefix(2)), others: Array(inCategory.dropFirst(2)))
    }

    func searchProducts(term: String) async throws(APIError) -> [Product] {
        Self.products.filter { $0.title.localizedCaseInsensitiveContains(term) }
    }

    func product(id: String) async throws(APIError) -> Product {
        guard let product = Self.products.first(where: { $0.id == id }) else { throw .notFound }
        return product
    }

    func submitEnquiry(_ enquiry: EnquiryRequest) async throws(APIError) -> EnquiryResponse {
        EnquiryResponse(reference: "STUB-REF-0001")
    }

    private static func make(
        _ id: String, _ title: String, _ price: Double, _ category: ProductCategory, rating: Double, image: String
    ) -> Product {
        Product(
            id: id,
            title: title,
            description: "About the \(title.lowercased()). Placeholder copy for previews and UI tests.",
            price: .init(amount: price, currency: "USD"),
            imageUrl: URL(string: "https://fakestoreapi.com/img/\(image)")!,
            category: category,
            rating: .init(average: rating, count: 100)
        )
    }
}
#endif
