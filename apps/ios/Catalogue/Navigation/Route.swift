import Foundation

enum Route: Hashable {
    case category(ProductCategory)
    case search(term: String)
    case product(id: String)
}
