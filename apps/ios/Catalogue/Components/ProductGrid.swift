import SwiftUI

struct ProductGrid: View {
    let products: [Product]

    private let columns = [GridItem(.adaptive(minimum: Theme.Layout.tileMinWidth), spacing: Theme.Spacing.l)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Spacing.l) {
            ForEach(products) { product in
                NavigationLink(value: Route.product(id: product.id)) {
                    ProductTile(product: product)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
