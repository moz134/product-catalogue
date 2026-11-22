import Foundation
import Testing
@testable import Catalogue

/// The API's tests validate the same fixtures against the Zod contract.
struct ContractFixtureTests {
    private func decode<T: Decodable>(_ type: T.Type, _ file: String) throws -> T {
        try JSONDecoder().decode(type, from: Fixtures.data(file))
    }

    @Test func product() throws {
        let product = try decode(Product.self, "product.json")
        #expect(product.id == "1")
        #expect(product.price == .init(amount: 109.95, currency: "USD"))
        #expect(product.category == ProductCategory(slug: "mens-clothing", name: "Men's clothing"))
        #expect(product.rating == .init(average: 3.9, count: 120))
        #expect(product.imageUrl.host() == "fakestoreapi.com")
    }

    @Test func productList() throws {
        #expect(try decode(ItemsResponse<Product>.self, "product-list.json").items.count == 2)
    }

    @Test func categoryList() throws {
        let categories = try decode(ItemsResponse<ProductCategory>.self, "category-list.json").items
        #expect(categories.map(\.slug) == ["electronics", "jewelery", "mens-clothing", "womens-clothing"])
    }

    @Test func categoryPage() throws {
        let page = try decode(CategoryPage.self, "category-page.json")
        #expect(page.category.slug == "electronics")
        #expect(page.topRated.map(\.id) == ["9"])
        #expect(page.others.map(\.id) == ["10"])
    }

    @Test func enquiryRequestRoundTripsExactly() throws {
        let data = try Fixtures.data("enquiry-request.json")
        let request = try JSONDecoder().decode(EnquiryRequest.self, from: data)
        let reencoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? NSDictionary
        let original = try JSONSerialization.jsonObject(with: data) as? NSDictionary
        #expect(reencoded == original)
    }

    @Test func enquiryResponse() throws {
        #expect(try decode(EnquiryResponse.self, "enquiry-response.json").reference.count == 36)
    }

    @Test func errorBodies() throws {
        let validation = try decode(APIErrorResponse.self, "error-validation.json")
        #expect(validation.error.code == "VALIDATION_ERROR")
        #expect(validation.error.fields?["email"] == ["Please enter a valid email address"])
        #expect(try decode(APIErrorResponse.self, "error-not-found.json").error.fields == nil)
    }
}
