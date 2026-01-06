import SwiftUI

struct RoundedCorners: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct SpeechRecorderView: View {
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @Binding var recordingDuration: TimeInterval
    @Binding var isSubmitting: Bool
    let stopRecording: (Bool) -> Void
    let formatDuration: (TimeInterval) -> String
    let brandPurple: Color
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                RoundedCorners(radius: 20, corners: [.topLeft, .topRight])
                    .fill(brandPurple)
                    .frame(height: 110)
                
                VStack {
                    Spacer().frame(height: 10)
                    
                    // Privacy indicator
                    HStack(alignment: .center) {
                        Spacer()
                        if speechRecognizer.supportsOnDeviceRecognition {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.9))
                                Text(String(localized: "app.speech.ondevice"))
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
                        Button(action: {
                            stopRecording(false)
                        }) {
                            Circle()
                                .fill(brandPurple.opacity(0.7))
                                .frame(width: 50, height: 50)
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
                            ForEach(0..<30, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.white)
                                    .frame(width: 2, height: speechRecognizer.audioLevels[index] * 30)
                            }
                        }
                        .padding(.top, 10)
                        
                        Text(formatDuration(recordingDuration))
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 45, alignment: .center)
                        
                        Button(action: {
                            let buttonPressTime = Date()
                            Logger.shared.log("Submit button pressed")
                            
                            DispatchQueue.main.async {
                                withAnimation(Animation.easeIn(duration: 0.1)) {
                                    isSubmitting = true
                                }
                                
                                Logger.shared.log("Submit state set to true: \(Date().timeIntervalSince(buttonPressTime) * 1000)ms after press")
                                
                                DispatchQueue.main.async {
                                    stopRecording(true)
                                    
                                    Logger.shared.log("stopRecording called: \(Date().timeIntervalSince(buttonPressTime) * 1000)ms after press")
                                }
                            }
                        }) {
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
                                                    .animation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: isSubmitting)
                                                
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                                    .tint(brandPurple)
                                                    .scaleEffect(1.3)
                                            }
                                            .onAppear {
                                                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                                                    // This empty block triggers the animation
                                                }
                                                Logger.shared.log("Spinner onAppear triggered")
                                            }
                                        } else {
                                            Image(systemName: "arrow.up")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(brandPurple)
                                        }
                                    }
                                )
                                // Add transition for spinner to emphasize its appearance
                                .animation(.easeIn(duration: 0.15), value: isSubmitting)
                        }
                        .padding(.trailing, 5)
                        .disabled(isSubmitting)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(brandPurple)
                .frame(height: UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 34)
        }
        .transition(.move(edge: .bottom))
        .animation(.easeInOut(duration: 0.3), value: speechRecognizer.isRecording)
        .zIndex(90)
        .edgesIgnoringSafeArea(.bottom)
    }
}
