import Foundation
@testable import Catalogue

actor FakeCatalogueAPI: CatalogueAPI {
    var featured: Result<[Product], APIError> = .success(Sample.products)
    var categoryList: Result<[ProductCategory], APIError> = .success([Sample.electronics, Sample.jewelery])
    var categoryPageResult: Result<CategoryPage, APIError> = .success(
        CategoryPage(category: Sample.electronics, topRated: Array(Sample.products.prefix(2)), others: [Sample.products[2]])
    )
    var searchResult: Result<[Product], APIError> = .success([Sample.products[1]])
    var productResult: Result<Product, APIError> = .success(Sample.products[0])
    var enquiryResult: Result<EnquiryResponse, APIError> = .success(EnquiryResponse(reference: "ref-123"))

    private(set) var calls: [String] = []
    private(set) var sentEnquiries: [EnquiryRequest] = []

    func set(featured: Result<[Product], APIError>) { self.featured = featured }
    func set(categoryPage: Result<CategoryPage, APIError>) { self.categoryPageResult = categoryPage }
    func set(product: Result<Product, APIError>) { self.productResult = product }
    func set(enquiry: Result<EnquiryResponse, APIError>) { self.enquiryResult = enquiry }

    func featuredProducts() async throws(APIError) -> [Product] {
        calls.append("featured")
        return try featured.get()
    }

    func categories() async throws(APIError) -> [ProductCategory] {
        calls.append("categories")
        return try categoryList.get()
    }

    func categoryPage(slug: String) async throws(APIError) -> CategoryPage {
        calls.append("categoryPage:\(slug)")
        return try categoryPageResult.get()
    }

    func searchProducts(term: String) async throws(APIError) -> [Product] {
        calls.append("search:\(term)")
        return try searchResult.get()
    }

    func product(id: String) async throws(APIError) -> Product {
        calls.append("product:\(id)")
        return try productResult.get()
    }

    func submitEnquiry(_ enquiry: EnquiryRequest) async throws(APIError) -> EnquiryResponse {
        calls.append("enquiry")
        sentEnquiries.append(enquiry)
        return try enquiryResult.get()
    }
}

enum Sample {
    static let electronics = ProductCategory(slug: "electronics", name: "Electronics")
    static let jewelery = ProductCategory(slug: "jewelery", name: "Jewelery")

    static let products: [Product] = (1...5).map { index in
        Product(
            id: String(index),
            title: "Product \(index)",
            description: "About product \(index)",
            price: .init(amount: Double(index) * 10, currency: "USD"),
            imageUrl: URL(string: "https://images.example.com/\(index).png")!,
            category: index <= 3 ? electronics : jewelery,
            rating: .init(average: 4, count: 10)
        )
    }
}
