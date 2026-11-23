import SwiftUI

struct PriceText: View {
    let price: Product.Price
    var font: Font = Theme.Fonts.price

    var body: some View {
        Text(price.amount, format: .currency(code: price.currency))
            .font(font)
            .monospacedDigit()
    }
}
