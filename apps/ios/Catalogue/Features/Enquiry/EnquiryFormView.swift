import SwiftUI

struct EnquiryFormView: View {
    @State private var model: EnquiryViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: EnquiryField?

    init(api: any CatalogueAPI, product: Product) {
        _model = State(initialValue: EnquiryViewModel(api: api, product: product))
    }

    var body: some View {
        NavigationStack {
            Group {
                if case .sent(let reference) = model.state {
                    ThankYouView(product: model.product, reference: reference) { dismiss() }
                } else {
                    form
                }
            }
            .navigationTitle(model.state == .editing || model.isSubmitting ? "Enquire" : "")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(model.isSubmitting)
    }

    private var form: some View {
        Form {
            Section {
                Text(model.product.title)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.textMuted)
            } header: {
                Text("Product")
            }

            if let formError = model.formError {
                Section {
                    Label(formError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.Colors.danger)
                        .accessibilityIdentifier("enquiry-form-error")
                }
            }

            Section("Your details") {
                field(.name, "Name", text: $model.input.name, contentType: .name)
                field(.email, "Email", text: $model.input.email, contentType: .emailAddress, keyboard: .emailAddress)
                field(.phone, "Phone (optional)", text: $model.input.phone, contentType: .telephoneNumber, keyboard: .phonePad)
            }

            Section("Message (optional)") {
                TextField("Anything we should know?", text: $model.input.message, axis: .vertical)
                    .lineLimit(3...8)
                    .focused($focusedField, equals: .message)
                    .onChange(of: model.input.message) { model.didEdit(.message) }
                    .accessibilityIdentifier("enquiry-message")
                errorText(for: .message)
            }
        }
        .disabled(model.isSubmitting)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                if model.isSubmitting {
                    ProgressView()
                } else {
                    Button("Send") { Task { await submit() } }
                        .accessibilityIdentifier("enquiry-send")
                }
            }
        }
        .onAppear { focusedField = .name }
    }

    private func submit() async {
        await model.submit()
        focusedField = EnquiryField.allCases.first { model.fieldErrors[$0] != nil }
    }

    @ViewBuilder
    private func field(
        _ field: EnquiryField,
        _ label: String,
        text: Binding<String>,
        contentType: UITextContentType,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        TextField(label, text: text)
            .textContentType(contentType)
            .keyboardType(keyboard)
            .textInputAutocapitalization(field == .name ? .words : .never)
            .autocorrectionDisabled(field != .name)
            .focused($focusedField, equals: field)
            .onChange(of: text.wrappedValue) { model.didEdit(field) }
            .accessibilityIdentifier("enquiry-\(field.rawValue)")
            .accessibilityHint(model.fieldErrors[field] ?? "")
        errorText(for: field)
    }

    @ViewBuilder
    private func errorText(for field: EnquiryField) -> some View {
        if let message = model.fieldErrors[field] {
            Text(message)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.danger)
                .accessibilityIdentifier("enquiry-\(field.rawValue)-error")
        }
    }
}

struct ThankYouView: View {
    let product: Product
    let reference: String
    let done: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.Colors.success)
                .accessibilityHidden(true)
            Text("Thank you")
                .font(Theme.Fonts.screenTitle)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("thank-you-title")
            Text("We've received your enquiry about **\(product.title)** and will be in touch soon.")
                .multilineTextAlignment(.center)
            Text("Reference: \(reference)")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textMuted)
                .textSelection(.enabled)
                .accessibilityIdentifier("thank-you-reference")
            Button("Done", action: done)
                .buttonStyle(.borderedProminent)
                .padding(.top, Theme.Spacing.l)
        }
        .padding(Theme.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }
}

#if DEBUG
#Preview {
    EnquiryFormView(api: StubCatalogueAPI(), product: StubCatalogueAPI.products[1])
}
#endif
