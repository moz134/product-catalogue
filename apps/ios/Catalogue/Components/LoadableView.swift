import SwiftUI

struct LoadableView<Value, Content: View>: View {
    let state: LoadState<Value>
    var loadingLabel: LocalizedStringKey = "Loading…"
    let retry: () async -> Void
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView(loadingLabel)
                .frame(maxWidth: .infinity, minHeight: 160)
        case .failed(let error):
            ErrorStateView(error: error, retry: retry)
        case .loaded(let value):
            content(value)
        }
    }
}

struct ErrorStateView: View {
    let error: APIError
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.userMessage)
        } actions: {
            Button("Try again") { Task { await retry() } }
                .buttonStyle(.borderedProminent)
        }
        .accessibilityIdentifier("error-state")
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.Fonts.sectionTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}
