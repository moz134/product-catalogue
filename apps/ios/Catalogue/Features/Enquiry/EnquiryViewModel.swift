import Foundation
import Observation

@MainActor
@Observable
final class EnquiryViewModel {
    enum SubmitState: Equatable {
        case editing
        case submitting
        case sent(reference: String)
    }

    let product: Product
    var input = EnquiryInput()
    private(set) var fieldErrors: [EnquiryField: String] = [:]
    /// A problem not tied to one field (network down, email delivery failed...).
    private(set) var formError: String?
    private(set) var state: SubmitState = .editing

    private let api: any CatalogueAPI

    init(api: any CatalogueAPI, product: Product) {
        self.api = api
        self.product = product
    }

    var isSubmitting: Bool { state == .submitting }

    func submit() async {
        guard state == .editing else { return }
        formError = nil
        fieldErrors = EnquiryValidator.validate(input)
        guard fieldErrors.isEmpty else { return }

        state = .submitting
        do {
            let response = try await api.submitEnquiry(EnquiryValidator.request(for: input, productID: product.id))
            state = .sent(reference: response.reference)
        } catch {
            state = .editing
            handle(error)
        }
    }

    func didEdit(_ field: EnquiryField) {
        fieldErrors[field] = nil
    }

    private func handle(_ error: APIError) {
        if case .validation(let message, let fields) = error {
            for field in EnquiryField.allCases {
                if let first = fields[field.rawValue]?.first { fieldErrors[field] = first }
            }
            if fieldErrors.isEmpty { formError = message }
        } else {
            formError = error.userMessage
        }
    }
}
