import SwiftUI

struct CategoryView: View {
    @State private var model: CategoryViewModel

    init(api: any CatalogueAPI, category: ProductCategory) {
        _model = State(initialValue: CategoryViewModel(api: api, category: category))
    }

    var body: some View {
        ScrollView {
            LoadableView(state: model.page, loadingLabel: "Loading category…", retry: model.load) { page in
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        SectionTitle(text: "Top rated")
                        ProductGrid(products: page.topRated)
                    }
                    if !page.others.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                            SectionTitle(text: "More in \(page.category.name)")
                            ProductGrid(products: page.others)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.l)
        }
        .background(Theme.Colors.background)
        .navigationTitle(model.category.name)
        .task { await model.load() }
        .refreshable { await model.load() }
    }
}

#if DEBUG
#Preview {
    NavigationStack { CategoryView(api: StubCatalogueAPI(), category: StubCatalogueAPI.electronics) }
}
#endif
