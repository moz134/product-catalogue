import Foundation

// Mirrors packages/shared/src/catalogue.ts; ContractFixtureTests keeps them in sync.

struct ProductCategory: Codable, Hashable, Sendable, Identifiable {
    /// URL-safe identifier, e.g. "mens-clothing".
    let slug: String
    let name: String

    var id: String { slug }
}

struct Product: Codable, Hashable, Sendable, Identifiable {
    struct Price: Codable, Hashable, Sendable {
        let amount: Double
        let currency: String
    }

    struct Rating: Codable, Hashable, Sendable {
        let average: Double
        let count: Int
    }

    /// A string, not a number, so future data sources (UUIDs, SKUs) fit without a contract change.
    let id: String
    let title: String
    let description: String
    let price: Price
    let imageUrl: URL
    let category: ProductCategory
    let rating: Rating
}

struct CategoryPage: Codable, Hashable, Sendable {
    let category: ProductCategory
    let topRated: [Product]
    let others: [Product]
}

/// List responses are wrapped in `{ "items": [...] }` so pagination can be added later.
struct ItemsResponse<Item: Codable & Sendable>: Codable, Sendable {
    let items: [Item]
}
