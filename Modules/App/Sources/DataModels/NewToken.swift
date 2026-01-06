public struct NewToken: Codable {
    public let code: Int
    public let status: Int
    public let token: String
    
    // Define coding keys
    private enum CodingKeys: String, CodingKey {
        case code = "Code"
        case status = "Status" 
        case token = "Token"
    }
}

