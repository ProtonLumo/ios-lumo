import Foundation

/// Error response received from the WebView's JavaScript layer
///
/// This type can only be decoded if the status is "error". Decoding will fail (return nil) for any other status.
struct ComposerErrorResponse: Equatable, Decodable {
    let result: Result

    struct Result: Equatable, Decodable {
        let status: String
        let error: String
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let result = try container.decode(Result.self, forKey: .result)

        guard result.status == "error" else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Status must be 'error' but got '\(result.status)'"
                )
            )
        }

        self.result = result
    }

    enum CodingKeys: String, CodingKey {
        case result
    }
}
