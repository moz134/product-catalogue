import Foundation
import Observation

@MainActor
@Observable
final class ProductDetailViewModel {
    let productID: String
    private(set) var product: LoadState<Product> = .idle
    var isEnquiring = false

    let api: any CatalogueAPI

    init(api: any CatalogueAPI, productID: String) {
        self.api = api
        self.productID = productID
    }

    func load() async {
        if product.value == nil { product = .loading }
        if let result = await LoadState.run({ try await api.product(id: productID) }) { product = result }
    }
}
