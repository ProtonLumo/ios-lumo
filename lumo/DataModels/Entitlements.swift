import Foundation

public struct DescriptionEntitlement: Decodable, Equatable, Hashable, Sendable {

    public let type: String
    public let text: String
    public let iconName: String
    public let hint: String?

    public init(type: String, text: String, iconName: String, hint: String? = nil) {
        self.type = type
        self.text = text
        self.iconName = iconName
        self.hint = hint
    }
}

public struct ProgressEntitlement: Decodable, Equatable, Hashable, Sendable {

    public let type: String
    public let text: String
    public let min: Int
    public let max: Int
    public let current: Int
    public let iconName: String?

    public init(type: String, text: String, min: Int, max: Int, current: Int, iconName: String? = nil) {
        self.type = type
        self.text = text
        self.min = min
        self.max = max
        self.current = current
        self.iconName = iconName
    }
}

public enum EntitlementType: String, Decodable, Equatable, Sendable {
    case description
    case progress
}

public enum Entitlement: Decodable, Equatable, Hashable, Sendable {

    case progress(ProgressEntitlement)
    case description(DescriptionEntitlement)

    enum CodingKeys: CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EntitlementType.self, forKey: .type)

        let singleContainer = try decoder.singleValueContainer()

        switch type {
        case .progress:
            self = .progress(try singleContainer.decode(ProgressEntitlement.self))
        case .description:
            self = .description(try singleContainer.decode(DescriptionEntitlement.self))
        }
    }
}
