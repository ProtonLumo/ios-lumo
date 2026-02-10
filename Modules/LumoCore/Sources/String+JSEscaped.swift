import Foundation

// MARK: - String Extension for JS Escaping
extension String {
    /// Properly escape string for JavaScript injection
    public var jsEscaped: String {
        self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")  // Line separator
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")  // Paragraph separator
    }
}
