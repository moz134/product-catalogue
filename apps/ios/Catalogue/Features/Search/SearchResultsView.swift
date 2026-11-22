import SwiftUI

struct SearchResultsView: View {
    @State private var model: SearchViewModel

    init(api: any CatalogueAPI, term: String) {
        _model = State(initialValue: SearchViewModel(api: api, term: term))
    }

    var body: some View {
        ScrollView {
            LoadableView(state: model.results, loadingLabel: "Searching…", retry: model.load) { products in
                if products.isEmpty {
                    ContentUnavailableView.search(text: model.term)
                } else {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        Text(products.count == 1 ? "1 product found" : "\(products.count) products found")
                            .foregroundStyle(Theme.Colors.textMuted)
                            .accessibilityIdentifier("search-result-count")
                        ProductGrid(products: products)
                    }
                }
            }
            .padding(Theme.Spacing.l)
        }
        .background(Theme.Colors.background)
        .navigationTitle("“\(model.term)”")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
    }
}

#if DEBUG
#Preview {
    NavigationStack { SearchResultsView(api: StubCatalogueAPI(), term: "ssd") }
}
#endif
