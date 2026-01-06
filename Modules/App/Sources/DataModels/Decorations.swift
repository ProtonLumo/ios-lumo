import Foundation

public struct StarredDecoration: Decodable, Equatable, Hashable, Sendable {

    public let type: String
    public let iconName: String

    public init(type: String, iconName: String) {
        self.type = type
        self.iconName = iconName
    }
}

public struct BadgeDecoration: Decodable, Equatable, Hashable, Sendable {

    public let type: String
    public let text: String
    public let anchor: String
    public let planId: String?

    public init(type: String, text: String, anchor: String, planId: String?) {
        self.type = type
        self.text = text
        self.anchor = anchor
        self.planId = planId
    }
}

public enum DecorationType: String, Decodable, Equatable, Hashable, Sendable {

    case starred
    case badge
}

public enum Decoration: Decodable, Equatable, Hashable, Sendable {

    case starred(StarredDecoration)
    case badge(BadgeDecoration)

    enum CodingKeys: CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(DecorationType.self, forKey: .type)

        let singleContainer = try decoder.singleValueContainer()

        switch type {
        case .starred:
            self = .starred(try singleContainer.decode(StarredDecoration.self))
        case .badge:
            self = .badge(try singleContainer.decode(BadgeDecoration.self))
        }
    }
}
