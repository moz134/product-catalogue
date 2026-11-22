import SwiftUI

@main
struct CatalogueApp: App {
    private let api = AppDependencies.makeAPI()

    var body: some Scene {
        WindowGroup {
            RootView(api: api)
                .tint(Theme.Colors.brand)
        }
    }
}
