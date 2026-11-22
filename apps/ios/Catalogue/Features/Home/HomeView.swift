import SwiftUI

struct HomeView: View {
    @State private var model: HomeViewModel
    let onSearch: (String) -> Void

    init(api: any CatalogueAPI, onSearch: @escaping (String) -> Void) {
        _model = State(initialValue: HomeViewModel(api: api))
        self.onSearch = onSearch
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                SearchBar(text: $model.searchText) {
                    if let term = model.submittedSearchTerm() { onSearch(term) }
                }

                categoryLinks

                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    SectionTitle(text: "Top rated")
                    LoadableView(state: model.featured, loadingLabel: "Loading top rated products…", retry: model.loadFeatured) { products in
                        if products.isEmpty {
                            ContentUnavailableView("No featured products yet", systemImage: "star")
                        } else {
                            ProductGrid(products: products)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.l)
        }
        .background(Theme.Colors.background)
        .navigationTitle("Catalogue")
        .task { await model.load() }
        .refreshable { await model.load() }
    }

    /// Hidden if categories fail to load, so the rest of the screen still works.
    @ViewBuilder
    private var categoryLinks: some View {
        if let categories = model.categories.value, !categories.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(categories) { category in
                        NavigationLink(value: Route.category(category)) {
                            Text(category.name)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, Theme.Spacing.m)
                                .padding(.vertical, Theme.Spacing.s)
                                .background(Theme.Colors.surface)
                                .clipShape(Capsule())
                        }
                        .accessibilityIdentifier("category-link-\(category.slug)")
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Categories")
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack { HomeView(api: StubCatalogueAPI(), onSearch: { _ in }) }
}
#endif
