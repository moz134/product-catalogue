import SwiftUI

/// Design tokens: views use only these values, so a new design is applied here.
/// System colours and text styles keep Dark Mode and Dynamic Type working.
enum Theme {
    enum Colors {
        static let brand = Color(red: 0.12, green: 0.23, blue: 0.37)
        static let accent = Color(red: 0.76, green: 0.44, blue: 0.24)
        static let background = Color(uiColor: .systemGroupedBackground)
        static let surface = Color(uiColor: .secondarySystemGroupedBackground)
        static let imageBackground = Color.white
        static let textMuted = Color.secondary
        static let danger = Color.red
        static let success = Color.green
        static let rating = Color.orange
    }

    enum Fonts {
        static let screenTitle = Font.largeTitle.weight(.semibold)
        static let sectionTitle = Font.title2.weight(.semibold)
        static let productTitle = Font.subheadline.weight(.semibold)
        static let detailTitle = Font.title2.weight(.bold)
        static let price = Font.headline
        static let detailPrice = Font.title.weight(.bold)
        static let caption = Font.caption
        static let body = Font.body
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 8
        static let card: CGFloat = 14
    }

    enum Layout {
        static let tileMinWidth: CGFloat = 160
        static let detailImageHeight: CGFloat = 300
    }
}
