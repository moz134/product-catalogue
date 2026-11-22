import SwiftUI

/// Searches only when the button or the keyboard's Search key is pressed, never per keystroke.
struct SearchBar: View {
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.Colors.textMuted)
                    .accessibilityHidden(true)
                TextField("Search products", text: $text)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit(onSubmit)
                    .accessibilityIdentifier("search-field")
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small))

            Button("Search", action: onSubmit)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("search-button")
        }
    }
}
