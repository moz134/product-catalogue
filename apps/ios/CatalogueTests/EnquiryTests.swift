import Foundation
import Testing
@testable import Catalogue

struct EnquiryValidatorTests {
    private let valid = EnquiryInput(name: "Ada Lovelace", email: "ada@example.com", phone: "", message: "")

    @Test func acceptsValidInput() {
        #expect(EnquiryValidator.validate(valid).isEmpty)
    }

    @Test func requiresNameAndEmailWithTheSameMessagesAsTheAPI() {
        let errors = EnquiryValidator.validate(EnquiryInput(name: "  ", email: ""))
        #expect(errors == [.name: "Please enter your name", .email: "Please enter your email"])
    }

    @Test(arguments: ["ada", "ada@", "ada@example", "ada example@x.com", "@example.com"])
    func rejectsInvalidEmails(email: String) {
        var input = valid
        input.email = email
        #expect(EnquiryValidator.validate(input)[.email] == "Please enter a valid email address")
    }

    @Test func checksPhoneCharactersAndLength() {
        var input = valid
        input.phone = "+44 (20) 1234-5678"
        #expect(EnquiryValidator.validate(input).isEmpty)

        input.phone = "call me"
        #expect(EnquiryValidator.validate(input)[.phone] == "Phone number can only contain digits, spaces and + ( ) -")

        input.phone = String(repeating: "1", count: 31)
        #expect(EnquiryValidator.validate(input)[.phone] == "Phone number is too long")
    }

    @Test func enforcesLengthLimits() {
        let input = EnquiryInput(
            name: String(repeating: "a", count: 101),
            email: "ada@example.com",
            message: String(repeating: "m", count: 2001)
        )
        let errors = EnquiryValidator.validate(input)
        #expect(errors[.name] == "Name is too long")
        #expect(errors[.message] == "Message is too long")
    }

    @Test func buildsATrimmedRequestWithoutEmptyOptionalFields() {
        let request = EnquiryValidator.request(
            for: EnquiryInput(name: " Ada ", email: " ada@example.com ", phone: "  ", message: " Hi "),
            productID: "7"
        )
        #expect(request == EnquiryRequest(productId: "7", name: "Ada", email: "ada@example.com", phone: nil, message: "Hi"))
    }
}

@MainActor
struct EnquiryViewModelTests {
    private func makeModel(_ api: FakeCatalogueAPI = FakeCatalogueAPI()) -> EnquiryViewModel {
        let model = EnquiryViewModel(api: api, product: Sample.products[1])
        model.input = EnquiryInput(name: "Ada", email: "ada@example.com", phone: "", message: "In stock?")
        return model
    }

    @Test func submitsContactDetailsAndShowsThankYou() async {
        let api = FakeCatalogueAPI()
        let model = makeModel(api)

        await model.submit()

        #expect(model.state == .sent(reference: "ref-123"))
        #expect(await api.sentEnquiries == [
            EnquiryRequest(productId: "2", name: "Ada", email: "ada@example.com", phone: nil, message: "In stock?"),
        ])
    }

    @Test func doesNotSendInvalidInput() async {
        let api = FakeCatalogueAPI()
        let model = makeModel(api)
        model.input.email = "nope"

        await model.submit()

        #expect(model.state == .editing)
        #expect(model.fieldErrors[.email] == "Please enter a valid email address")
        #expect(await api.sentEnquiries.isEmpty)
    }

    @Test func mapsServerFieldErrorsOntoTheForm() async {
        let api = FakeCatalogueAPI()
        await api.set(enquiry: .failure(.validation(message: "The request is invalid", fields: ["email": ["Email is not allowed"]])))
        let model = makeModel(api)

        await model.submit()

        #expect(model.state == .editing)
        #expect(model.fieldErrors == [.email: "Email is not allowed"])
        #expect(model.formError == nil)
    }

    @Test func showsDeliveryFailuresAndKeepsWhatTheUserTyped() async {
        let api = FakeCatalogueAPI()
        await api.set(enquiry: .failure(.server(status: 502, code: "EMAIL_DELIVERY_FAILED", message: "We could not send your enquiry. Please try again shortly.")))
        let model = makeModel(api)

        await model.submit()

        #expect(model.state == .editing)
        #expect(model.formError == "We could not send your enquiry. Please try again shortly.")
        #expect(model.input.name == "Ada")
    }

    @Test func editingAFieldClearsItsError() async {
        let model = makeModel()
        model.input.name = ""
        await model.submit()
        #expect(model.fieldErrors[.name] != nil)

        model.didEdit(.name)

        #expect(model.fieldErrors[.name] == nil)
    }
}
