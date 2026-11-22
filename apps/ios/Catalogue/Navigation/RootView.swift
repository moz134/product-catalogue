import SwiftUI

struct RootView: View {
    let api: any CatalogueAPI
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(api: api, onSearch: { term in path.append(.search(term: term)) })
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .category(let category):
                        CategoryView(api: api, category: category)
                    case .search(let term):
                        SearchResultsView(api: api, term: term)
                    case .product(let id):
                        ProductDetailView(api: api, productID: id)
                    }
                }
        }
    }
}
