import Foundation

/// Error response received from the WebView's JavaScript layer
///
/// This type can only be decoded if the status is "error". Decoding will fail (return nil) for any other status.
struct ComposerErrorResponse: Equatable, Decodable {
    let status: String
    let error: WebComposerError

    enum CodingKeys: String, CodingKey {
        case status
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let status: String = try container.decode(String.self, forKey: .status)
        let errorString: String = try container.decode(String.self, forKey: .error)

        guard status == "error" else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Status must be 'error' but got '\(status)'"
                )
            )
        }

        self.status = status
        self.error = WebComposerError(rawValue: errorString) ?? .unknown
    }
}
