import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    let term: String
    private(set) var results: LoadState<[Product]> = .idle

    private let api: any CatalogueAPI

    init(api: any CatalogueAPI, term: String) {
        self.api = api
        self.term = term
    }

    func load() async {
        if results.value == nil { results = .loading }
        if let result = await LoadState.run({ try await api.searchProducts(term: term) }) { results = result }
    }
}
