import Foundation

/// `CATALOGUE_API_BASE_URL` (set in the scheme, e.g. your Mac's IP for a real device) wins over
/// `CatalogueAPIBaseURL` in Info.plist.
enum AppConfig {
    static let defaultBaseURL = URL(string: "http://localhost:3000/api/v1")!

    static func apiBaseURL(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundle: Bundle = .main
    ) -> URL {
        if let value = environment["CATALOGUE_API_BASE_URL"], let url = URL(string: value), url.scheme != nil {
            return url
        }
        if let value = bundle.object(forInfoDictionaryKey: "CatalogueAPIBaseURL") as? String,
           let url = URL(string: value) {
            return url
        }
        return defaultBaseURL
    }
}
