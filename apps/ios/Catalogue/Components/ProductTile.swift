import SwiftUI

struct ProductTile: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProductImage(url: product.imageUrl)
                .padding(Theme.Spacing.l)
                .aspectRatio(1, contentMode: .fit)
                .background(Theme.Colors.imageBackground)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(product.category.name)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textMuted)
                Text(product.title)
                    .font(Theme.Fonts.productTitle)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                HStack {
                    PriceText(price: product.price)
                    Spacer(minLength: Theme.Spacing.xs)
                    RatingView(rating: product.rating)
                }
                .padding(.top, Theme.Spacing.xs)
            }
            .padding(Theme.Spacing.m)
        }
        .foregroundStyle(.primary)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("product-tile-\(product.id)")
    }
}
