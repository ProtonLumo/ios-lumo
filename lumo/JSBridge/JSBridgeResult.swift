import Foundation

/// Result type for JavaScript execution
enum JSBridgeResult {
    case success(Any?)
    case failure(JSBridgeError)
    
    /// Extract successful value
    var value: Any? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
    
    /// Extract error
    var error: JSBridgeError? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
    
    /// Check if successful
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

/// Errors that can occur during JavaScript bridge operations
enum JSBridgeError: Error, LocalizedError {
    case webViewNotReady
    case scriptNotFound(String)
    case executionFailed(String)
    case timeout
    case invalidResponse(String)
    case editorNotFound
    case paymentApiUnavailable
    case networkError(Error)
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .webViewNotReady:
            return "WebView is not ready for script execution"
        case .scriptNotFound(let script):
            return "Script not found: \(script)"
        case .executionFailed(let reason):
            return "Script execution failed: \(reason)"
        case .timeout:
            return "Script execution timed out"
        case .invalidResponse(let details):
            return "Invalid response from JavaScript: \(details)"
        case .editorNotFound:
            return "Editor element not found in DOM"
        case .paymentApiUnavailable:
            return "Payment API is not available"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    /// Whether this error is recoverable with retry
    var isRecoverable: Bool {
        switch self {
        case .webViewNotReady, .timeout, .editorNotFound:
            return true
        case .scriptNotFound, .executionFailed, .invalidResponse, .paymentApiUnavailable:
            return false
        case .networkError, .unknownError:
            return true
        }
    }
}

/// Response from JavaScript execution
struct JSResponse: Codable {
    let success: Bool
    let data: AnyCodable?
    let reason: String?
    let action: String?
    let theme: String?
    let exists: Bool?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        data = try container.decodeIfPresent(AnyCodable.self, forKey: .data)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        action = try container.decodeIfPresent(String.self, forKey: .action)
        theme = try container.decodeIfPresent(String.self, forKey: .theme)
        exists = try container.decodeIfPresent(Bool.self, forKey: .exists)
    }
    
    enum CodingKeys: String, CodingKey {
        case success, data, reason, action, theme, exists
    }
}

/// Type-erased Codable wrapper for Any
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

