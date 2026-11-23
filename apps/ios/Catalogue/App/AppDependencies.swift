import Foundation

/// Composition root: the only place that chooses the `CatalogueAPI` implementation.
enum AppDependencies {
    static let stubLaunchArgument = "-UITestStubAPI"

    static func makeAPI(arguments: [String] = ProcessInfo.processInfo.arguments) -> any CatalogueAPI {
        #if DEBUG
        if arguments.contains(stubLaunchArgument) {
            return StubCatalogueAPI()
        }
        #endif
        return HTTPCatalogueAPI(baseURL: AppConfig.apiBaseURL())
    }
}
