import SwiftUI
import ProtonUIFoundations

struct ProgressEntitlementView: View {

    let currentValue: Int
    let maxValue: Int
    let text: String

    @State private var isShown: Bool = false

    private var currentProgress: Double {
        Double(currentValue) / Double(maxValue)
    }

    private struct Constants {
        static let progressLineHeight: CGFloat = 4
        static let progressAnimationDuration: TimeInterval = 1.0

        static func progressColor(maxValue: Int, currentValue: Int) -> Color {
            let progress = Double(currentValue) / Double(maxValue)
            if progress < 0.5 {
                return Theme.color.iconAccent
            } else if progress >= 0.5 && progress < 0.9 {
                return Theme.color.notificationWarning
            } else {
                return Theme.color.notificationError
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(text)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.color.interactionWeak)
                        .frame(height: Constants.progressLineHeight)
                    Capsule()
                        .fill(Constants.progressColor(maxValue: maxValue, currentValue: currentValue))
                        .frame(width: isShown ? proxy.size.width * currentProgress : 0, height: Constants.progressLineHeight)
                        .animation(.easeInOut(duration: Constants.progressAnimationDuration), value: isShown)
                }
            }
            .frame(height: 0)
        }
        .onAppear {
            Task {
                await animate(duration: Constants.progressAnimationDuration) {
                    isShown = true
                }
            }
        }
    }
}

