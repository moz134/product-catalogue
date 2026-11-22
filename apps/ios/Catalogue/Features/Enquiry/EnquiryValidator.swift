import Foundation

/// Mirrors `enquiryRequestSchema` in packages/shared/src/enquiry.ts (same limits and messages)
/// for instant feedback. The API validates again.
enum EnquiryField: String, CaseIterable, Hashable, Sendable {
    case name, email, phone, message
}

struct EnquiryInput: Equatable, Sendable {
    var name = ""
    var email = ""
    var phone = ""
    var message = ""
}

enum EnquiryValidator {
    static let nameMaxLength = 100
    static let emailMaxLength = 254
    static let phoneMaxLength = 30
    static let messageMaxLength = 2000

    /// Returns one message per invalid field; empty means valid.
    static func validate(_ input: EnquiryInput) -> [EnquiryField: String] {
        var errors: [EnquiryField: String] = [:]
        let name = input.name.trimmed
        let email = input.email.trimmed
        let phone = input.phone.trimmed
        let message = input.message.trimmed

        if name.isEmpty {
            errors[.name] = "Please enter your name"
        } else if name.count > nameMaxLength {
            errors[.name] = "Name is too long"
        }

        if email.isEmpty {
            errors[.email] = "Please enter your email"
        } else if email.count > emailMaxLength {
            errors[.email] = "Email is too long"
        } else if !isValidEmail(email) {
            errors[.email] = "Please enter a valid email address"
        }

        if phone.count > phoneMaxLength {
            errors[.phone] = "Phone number is too long"
        } else if phone.contains(where: { !"0123456789 +()-".contains($0) }) {
            errors[.phone] = "Phone number can only contain digits, spaces and + ( ) -"
        }

        if message.count > messageMaxLength {
            errors[.message] = "Message is too long"
        }
        return errors
    }

    static func request(for input: EnquiryInput, productID: String) -> EnquiryRequest {
        EnquiryRequest(
            productId: productID,
            name: input.name.trimmed,
            email: input.email.trimmed,
            phone: input.phone.trimmed.nilIfEmpty,
            message: input.message.trimmed.nilIfEmpty
        )
    }

    /// Pragmatic check (something@domain.tld). Deliverability is the mail server's job.
    static func isValidEmail(_ email: String) -> Bool {
        email.wholeMatch(of: /[^\s@]+@[^\s@]+\.[^\s@]{2,}/) != nil
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
