import SwiftUI

typealias SwiftColor = SwiftUI.Color

extension DS {
    public enum Color {
        public static let primary = SwiftColor.lumoPrimary

        public enum Background {
            public static let norm = SwiftColor.backgroundNorm
            public static let normDarkOnly = SwiftColor.slate950
            public static let weak = SwiftColor.backgroundWeak
            public static let weakDarkOnly = SwiftColor.backgroundWeakDark
        }

        public enum Border {
            public static let norm = SwiftColor.borderNorm
            public static let weak = SwiftColor.borderWeak
            public static let weakDark = SwiftColor.borderWeakDark
        }

        public enum Interaction {
            public static let defaultHover = SwiftColor.interactionDefaultHover
        }

        public enum Text {
            public static let hint = SwiftColor.textHint
            public static let hintDark = SwiftColor.textHintDark
            public static let norm = SwiftColor.textNorm
            public static let normDarkOnly = SwiftColor.textNormDark
            public static let weak = SwiftColor.textWeak
            public static let weakDark = SwiftColor.textWeakDark
        }

        // MARK: - Deprecated

        public static let gradient = SwiftColor.gradient
        public static let middleGray = SwiftColor.middleGray
        public static let overlay = SwiftColor.overlay
    }
}
