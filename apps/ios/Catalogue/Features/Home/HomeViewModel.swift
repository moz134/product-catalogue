import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private(set) var featured: LoadState<[Product]> = .idle
    private(set) var categories: LoadState<[ProductCategory]> = .idle
    var searchText = ""

    private let api: any CatalogueAPI

    init(api: any CatalogueAPI) {
        self.api = api
    }

    func load() async {
        async let featuredResult: Void = loadFeatured()
        async let categoriesResult: Void = loadCategories()
        _ = await (featuredResult, categoriesResult)
    }

    func loadFeatured() async {
        if featured.value == nil { featured = .loading }
        if let result = await LoadState.run({ try await api.featuredProducts() }) { featured = result }
    }

    func loadCategories() async {
        if categories.value == nil { categories = .loading }
        if let result = await LoadState.run({ try await api.categories() }) { categories = result }
    }

    /// `nil` when the box is blank.
    func submittedSearchTerm() -> String? {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return term.isEmpty ? nil : term
    }
}
