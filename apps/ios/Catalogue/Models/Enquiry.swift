import Foundation

// Mirrors packages/shared/src/enquiry.ts.

struct EnquiryRequest: Codable, Hashable, Sendable {
    let productId: String
    let name: String
    let email: String
    /// Omitted from the JSON when nil.
    let phone: String?
    let message: String?
}

struct EnquiryResponse: Codable, Hashable, Sendable {
    let reference: String
}
