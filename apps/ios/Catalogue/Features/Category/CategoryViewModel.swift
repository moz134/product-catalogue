import Foundation
import Observation

@MainActor
@Observable
final class CategoryViewModel {
    let category: ProductCategory
    private(set) var page: LoadState<CategoryPage> = .idle

    private let api: any CatalogueAPI

    init(api: any CatalogueAPI, category: ProductCategory) {
        self.api = api
        self.category = category
    }

    func load() async {
        if page.value == nil { page = .loading }
        if let result = await LoadState.run({ try await api.categoryPage(slug: category.slug) }) { page = result }
    }
}
