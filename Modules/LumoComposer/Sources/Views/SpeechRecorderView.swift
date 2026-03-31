import LumoDesignSystem
import LumoUI
import SwiftUI

public struct SpeechRecorderView: View {
    let state: SpeechStateStore.State
    let onSubmit: () -> Void
    let onCancel: () -> Void
    let onDismissPermission: () -> Void
    let onOpenSettings: () -> Void

    private let brandPurple = DS.Color.primary

    private var isSubmitting: Bool {
        if case .submitting = state { return true }
        return false
    }

    private var viewState: RecordingViewState {
        state.recordingViewState ?? .initial
    }

    public init(
        state: SpeechStateStore.State,
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onDismissPermission: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.state = state
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.onDismissPermission = onDismissPermission
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                VStack {
                    Spacer().frame(height: 10)

                    // Privacy indicator
                    HStack(alignment: .center) {
                        Spacer()
                        if viewState.isOnDevice {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.9))
                                Text(L10n.Speech.onDevice)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(14)
                        }
                        Spacer()
                    }

                    Spacer().frame(height: 4)

                    HStack(spacing: 15) {
                        Button(action: onCancel) {
                            Circle()
                                .fill(brandPurple.opacity(0.7))
                                .square(size: 50)
                                .overlay(
                                    Image(systemName: "xmark")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                        .padding(.leading, 5)
                        .disabled(isSubmitting)

                        // Waveform visualization
                        HStack(spacing: 2) {
                            ForEach(0..<AudioLevelNormalizer.barCount, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.white)
                                    .frame(width: 2, height: viewState.audioLevels[index] * 30)
                            }
                        }
                        .padding(.top, 10)

                        Text(formatDuration(viewState.duration))
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 45, alignment: .center)

                        Button(action: onSubmit) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Group {
                                        if isSubmitting {
                                            ZStack {
                                                Circle()
                                                    .fill(brandPurple.opacity(0.2))
                                                    .frame(width: 40, height: 40)
                                                    .scaleEffect(isSubmitting ? 1.2 : 1.0)
                                                    .animation(
                                                        Animation.easeInOut(duration: 0.7)
                                                            .repeatForever(autoreverses: true),
                                                        value: isSubmitting
                                                    )

                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                                    .tint(brandPurple)
                                                    .scaleEffect(1.3)
                                            }
                                        } else {
                                            Image(systemName: "arrow.up")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(brandPurple)
                                        }
                                    }
                                )
                                .animation(.easeIn(duration: 0.15), value: isSubmitting)
                        }
                        .padding(.trailing, 5)
                        .disabled(isSubmitting)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 110)
            .background {
                RoundedCorners(radius: 20, corners: [.topLeft, .topRight])
                    .fill(brandPurple)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .transition(.move(edge: .bottom))
        .zIndex(90)
    }

    // MARK: - Private

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct RoundedCorners: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
