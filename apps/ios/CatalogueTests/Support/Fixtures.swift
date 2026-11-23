import Foundation

/// The simulator runs on the host Mac, so tests read the shared fixtures straight from the repo.
enum Fixtures {
    static let directory = URL(filePath: #filePath)
        .deletingLastPathComponent() // Support
        .deletingLastPathComponent() // CatalogueTests
        .deletingLastPathComponent() // ios
        .deletingLastPathComponent() // apps
        .deletingLastPathComponent() // repo root
        .appending(path: "packages/shared/fixtures")

    static func data(_ name: String) throws -> Data {
        try Data(contentsOf: directory.appending(path: name))
    }
}
