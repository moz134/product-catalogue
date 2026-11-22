import SwiftUI

struct ProductDetailView: View {
    @State private var model: ProductDetailViewModel

    init(api: any CatalogueAPI, productID: String) {
        _model = State(initialValue: ProductDetailViewModel(api: api, productID: productID))
    }

    var body: some View {
        ScrollView {
            if case .failed(.notFound) = model.product {
                ContentUnavailableView(
                    "We couldn't find that product",
                    systemImage: "questionmark.square.dashed",
                    description: Text("It may have moved or no longer exists.")
                )
            } else {
                LoadableView(state: model.product, loadingLabel: "Loading product…", retry: model.load) { product in
                    details(product)
                }
            }
        }
        .background(Theme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .sheet(isPresented: $model.isEnquiring) {
            if let product = model.product.value {
                EnquiryFormView(api: model.api, product: product)
            }
        }
    }

    private func details(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            ProductImage(url: product.imageUrl)
                .padding(Theme.Spacing.xl)
                .frame(height: Theme.Layout.detailImageHeight)
                .background(Theme.Colors.imageBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

            NavigationLink(value: Route.category(product.category)) {
                Text(product.category.name).font(.subheadline)
            }

            Text(product.title)
                .font(Theme.Fonts.detailTitle)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("product-title")

            RatingView(rating: product.rating)
            PriceText(price: product.price, font: Theme.Fonts.detailPrice)

            Text(product.description)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textMuted)

            Button {
                model.isEnquiring = true
            } label: {
                Text("Enquire")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.s)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.accent)
            .accessibilityIdentifier("enquire-button")
        }
        .padding(Theme.Spacing.l)
    }
}

#if DEBUG
#Preview {
    NavigationStack { ProductDetailView(api: StubCatalogueAPI(), productID: "2") }
}
#endif
