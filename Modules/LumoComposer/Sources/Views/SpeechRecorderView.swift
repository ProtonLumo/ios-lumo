import LumoDesignSystem
import LumoUI
import SwiftUI

public struct SpeechRecorderView: View {
    let state: SpeechStateStore.State
    let onSubmit: () -> Void
    let onCancel: () -> Void

    public init(
        state: SpeechStateStore.State,
        onSubmit: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.state = state
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: .zero) {
            Spacer()
            VStack(alignment: .center) {
                Spacer().frame(height: DS.Spacing.mediumLight)

                transcriptionOnDevice

                Spacer().frame(height: DS.Spacing.small)

                HStack(spacing: DS.Spacing.large) {
                    cancelButton
                    audioWaveform
                    duration
                    submitButton
                }
            }
            .frame(maxWidth: .infinity, minHeight: 110)
            .geometryGroup()
            .background {
                RoundedCorners(radius: 20, corners: [.topLeft, .topRight])
                    .fill(brandPurple)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    // MARK: - Private

    private let brandPurple = DS.Color.primary

    private var transcriptionOnDevice: some View {
        HStack(spacing: DS.Spacing.compact) {
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
        .opacity(viewState.isOnDevice ? 1 : 0)
    }

    private var cancelButton: some View {
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
    }

    private var audioWaveform: some View {
        HStack(spacing: DS.Spacing.tiny) {
            ForEach(0..<AudioLevelNormalizer.barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white)
                    .frame(width: 2, height: viewState.audioLevels[index] * 30)
            }
        }
        .padding(.top, DS.Spacing.mediumLight)
    }

    private var duration: some View {
        Text(formatDuration(viewState.duration))
            .foregroundColor(.white)
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 45, alignment: .center)
    }

    private var submitButton: some View {
        Button(action: onSubmit) {
            Circle()
                .fill(Color.white)
                .square(size: 50)
                .overlay(
                    Group {
                        if isSubmitting {
                            ZStack {
                                Circle()
                                    .fill(brandPurple.opacity(0.2))
                                    .square(size: 40)
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
        .padding(.trailing, DS.Spacing.compact)
        .disabled(isSubmitting)
    }

    private var isSubmitting: Bool {
        if case .submitting = state { return true }
        return false
    }

    private var viewState: RecordingViewState {
        state.recordingViewState ?? .initial
    }

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
