import WidgetKit
import SwiftUI
import Intents
import os.log


class WidgetLogger {
    static let shared = WidgetLogger()
    private let logger: Logger
    
    private init() {
        logger = Logger(subsystem: "me.proton.lumo", category: "WidgetInteraction")
    }
    
    func log(_ message: String, isDebugOnly: Bool = false) {
        if !isDebugOnly {
            logger.log("\(message, privacy: .public)")
        }
        #if DEBUG
        print("Widget: \(message)")
        #endif
    }
    
    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
        #if DEBUG
        print("Widget Error: \(message)")
        #endif
    }
}


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: 
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: 
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: 
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


struct LumoWidgetEntry: TimelineEntry {
    let date: Date
    let searchHint: String
    var prompts: [TimePrompt] = []
    
    init(date: Date, searchHint: String, prompts: [TimePrompt] = []) {
        self.date = date
        self.searchHint = searchHint
        self.prompts = prompts
    }
}


struct TimePrompt: Identifiable {
    let labelKey: String
    let promptKey: String
    let id: String
    let icon: String
    
    var label: String {
        String(localized: LocalizedStringResource(stringLiteral: labelKey))
    }
    
    var prompt: String {
        String(localized: LocalizedStringResource(stringLiteral: promptKey))
    }
    
    var destination: String {
        // Create a proper character set for URL query values
        // We need to exclude &, =, and other special URL characters
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.remove(charactersIn: "!*'();:@&=+$,/?#[]")
        
        let encodedLabel = label.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? label
        let encodedPrompt = prompt.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? prompt
        
        let dest = "lumo://prompt?id=\(id)&source=widget&label=\(encodedLabel)&prompt=\(encodedPrompt)"
        WidgetLogger.shared.log("Created widget URL: \(dest)")
        return dest
    }
    
    init(labelKey: String, promptKey: String, id: String, icon: String) {
        self.labelKey = labelKey
        self.promptKey = promptKey
        self.id = id
        self.icon = icon
        WidgetLogger.shared.log("Created TimePrompt - Label: \(self.label), ID: \(id)")
    }
}


struct PromptButtonView: View {
    var label: String
    var destination: String
    var icon: String
    var textColor: Color
    var buttonBackgroundColor: Color
    
    var body: some View {
        Link(destination: URL(string: destination)!) {
            VStack(alignment: .center, spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(textColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(buttonBackgroundColor)
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .frame(height: 32)
            }
            .frame(height: 76)
            .accessibility(label: Text(String(localized: "widget.accessibility.openInLumo", defaultValue: "Open \(label) in Lumo")))
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            WidgetLogger.shared.log("Widget button appeared: \(label) with URL: \(destination)")
        }
    }
}


struct CompactPromptButtonView: View {
    var label: String
    var destination: String
    var icon: String
    var purpleColor: Color
    var orangeColor: Color
    
    var body: some View {
        Link(destination: URL(string: destination) ?? URL(string: "lumo://home?source=widget_fallback")!) {
            VStack(alignment: .center, spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(purpleColor)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(purpleColor.opacity(0.1))
                    )
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(purpleColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 28)
            }
            .frame(height: 70)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct ModernSpeechBubble: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let cornerRadius: CGFloat = 16
        let tipSize: CGFloat = 8 
        
        
        let mainRect = CGRect(
            x: rect.minX + tipSize,
            y: rect.minY,
            width: rect.width - tipSize,
            height: rect.height
        )
        
        let roundedRect = UIBezierPath(
            roundedRect: mainRect,
            cornerRadius: cornerRadius
        )
        
        path.addPath(Path(roundedRect.cgPath))
        
        
        path.move(to: CGPoint(x: rect.minX + tipSize, y: rect.midY - tipSize))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + tipSize, y: rect.midY + tipSize))
        
        return path
    }
}


struct LumoWidgetView: View {
    var entry: LumoWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    
    let purpleColor = Color(hex: "#6D4AFF")
    let lightPurpleColor = Color(hex: "#8B6FFF") // Lighter purple for better visibility in dark mode
    let orangeColor = Color(hex: "#FFAC2E")
    
    // Adaptive background color based on system appearance and rendering mode
    var backgroundColor: Color {
        if #available(iOSApplicationExtension 17.0, *), widgetRenderingMode == .vibrant {
            // Use clear background for vibrant/tinted mode
            return Color.clear
        }
        return colorScheme == .dark ? Color(hex: "#16141c") : Color.white
    }
    
    // Adaptive text/icon colors - use widget accent color for vibrant mode
    var textColor: Color {
        if #available(iOSApplicationExtension 17.0, *), widgetRenderingMode == .vibrant {
            return Color.primary
        }
        // In dark mode, use lighter purple for better contrast, in light mode use original purple
        return colorScheme == .dark ? lightPurpleColor : purpleColor
    }
    
    var bubbleBackgroundColor: Color {
        if #available(iOSApplicationExtension 17.0, *), widgetRenderingMode == .vibrant {
            return Color.primary.opacity(0.15)
        }
        // In dark mode, use lighter purple with higher opacity for visibility
        // Closer to original #6D4AFF but brighter for dark backgrounds
        return colorScheme == .dark ? lightPurpleColor.opacity(0.2) : purpleColor.opacity(0.1)
    }
    
    var buttonBackgroundColor: Color {
        if #available(iOSApplicationExtension 17.0, *), widgetRenderingMode == .vibrant {
            return Color.primary.opacity(0.15)
        }
        // In dark mode, use lighter purple with higher opacity
        return colorScheme == .dark ? lightPurpleColor.opacity(0.2) : purpleColor.opacity(0.1)
    }
    
    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            contentView
                .containerBackground(for: .widget) {
                    Color.clear
                }
                .widgetURL(nil)
                .onAppear {
                    WidgetLogger.shared.log("Widget view appeared (iOS 17+)", isDebugOnly: true)
                }
        } else {
            contentView
                .background(backgroundColor)
                .widgetURL(nil)
                .onAppear {
                    WidgetLogger.shared.log("Widget view appeared (iOS 16)", isDebugOnly: true)
                }
        }
    }
    
    private var contentView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    backgroundColor,
                    backgroundColor.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if family == .systemSmall {
                    VStack {
                        Spacer()
                        Image("LumoFront")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(purpleColor)
                        Spacer()
                    }
                } else {
                    
                    HStack(spacing: 10) {
 
                        Image("LumoFront")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 95)
                            .padding(.leading, 10)
                        
                        VStack(spacing: 10) {
                            ModernSpeechBubble()
                                .fill(bubbleBackgroundColor)
                                .frame(width: 210, height: 40)
                                .overlay(
                                    Text(entry.searchHint)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(textColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                )
                            
                            HStack(spacing: 10) {
                                
                                ForEach(entry.prompts.prefix(2), id: \.id) { prompt in
                                    PromptButtonView(
                                        label: prompt.label,
                                        destination: prompt.destination,
                                        icon: prompt.icon,
                                        textColor: textColor,
                                        buttonBackgroundColor: buttonBackgroundColor
                                    )
                                    .widgetURL(nil)
                                }
                            }
                            .padding(.horizontal, 10)
                        }
                    
                    
                    }.padding(.top, 3)
                }
            }
        }
    }
}


struct LumoWidgetProvider: TimelineProvider {
    typealias Entry = LumoWidgetEntry
    
    // Timeline update hours for better readability
    private enum TimelineUpdateHour {
        static let morning = 7
        static let lunch = 12
        static let evening = 18
        static let night = 22
    }

    func placeholder(in context: Context) -> LumoWidgetEntry {
        let defaultPrompts = [
            TimePrompt(labelKey: "widget.prompt.scamSpotting", promptKey: "widget.prompt.scamSpotting.full", id: "scam", icon: "questionmark.shield"),
            TimePrompt(labelKey: "widget.prompt.physicsExplained", promptKey: "widget.prompt.physicsExplained.full", id: "physics", icon: "atom")
        ]
        return LumoWidgetEntry(date: Date(), searchHint: String(localized: "widget.searchHint.default"), prompts: defaultPrompts)
    }

    func getSnapshot(in context: Context, completion: @escaping (LumoWidgetEntry) -> ()) {
        let defaultPrompts = [
            TimePrompt(labelKey: "widget.prompt.scamSpotting", promptKey: "widget.prompt.scamSpotting.full", id: "scam", icon: "questionmark.shield"),
            TimePrompt(labelKey: "widget.prompt.physicsExplained", promptKey: "widget.prompt.physicsExplained.full", id: "physics", icon: "atom")
        ]
        let entry = LumoWidgetEntry(date: Date(), searchHint: String(localized: "widget.searchHint.default"), prompts: defaultPrompts)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LumoWidgetEntry>) -> ()) {
        var entries: [LumoWidgetEntry] = []
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        let currentSuggestion = getTimeSensitiveSuggestion(hour: hour)
        WidgetLogger.shared.log("Timeline updated with new suggestions", isDebugOnly: true)
        entries.append(LumoWidgetEntry(
            date: now,
            searchHint: currentSuggestion.hint,
            prompts: currentSuggestion.prompts
        ))
        
        
        
        if let morningUpdate = calendar.date(bySettingHour: TimelineUpdateHour.morning, minute: 0, second: 0, of: now),
           morningUpdate > now {
            let morningContent = getTimeSensitiveSuggestion(hour: TimelineUpdateHour.morning)
            entries.append(LumoWidgetEntry(
                date: morningUpdate,
                searchHint: morningContent.hint,
                prompts: morningContent.prompts
            ))
        }
        
        
        if let lunchUpdate = calendar.date(bySettingHour: TimelineUpdateHour.lunch, minute: 0, second: 0, of: now),
           lunchUpdate > now {
            let lunchContent = getTimeSensitiveSuggestion(hour: TimelineUpdateHour.lunch)
            entries.append(LumoWidgetEntry(
                date: lunchUpdate,
                searchHint: lunchContent.hint,
                prompts: lunchContent.prompts
            ))
        }
        
        
        if let eveningUpdate = calendar.date(bySettingHour: TimelineUpdateHour.evening, minute: 0, second: 0, of: now),
           eveningUpdate > now {
            let eveningContent = getTimeSensitiveSuggestion(hour: TimelineUpdateHour.evening)
            entries.append(LumoWidgetEntry(
                date: eveningUpdate,
                searchHint: eveningContent.hint,
                prompts: eveningContent.prompts
            ))
        }
        
        if let nightUpdate = calendar.date(bySettingHour: TimelineUpdateHour.night, minute: 0, second: 0, of: now),
           nightUpdate > now {
            let nightContent = getTimeSensitiveSuggestion(hour: TimelineUpdateHour.night)
            entries.append(LumoWidgetEntry(
                date: nightUpdate,
                searchHint: nightContent.hint,
                prompts: nightContent.prompts
            ))
        }
        
        entries.sort { $0.date < $1.date }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}


struct LumoWidgetExtension: Widget {
    let kind: String = "LumoWidgetExtension"

    var body: some WidgetConfiguration {
        return StaticConfiguration(kind: kind, provider: LumoWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                LumoWidgetView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color.clear
                    }
            } else {
                LumoWidgetView(entry: entry)
            }
        }
        .configurationDisplayName(String(localized: "widget.displayname"))
        .description(String(localized: "widget.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}


struct LumoWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Medium - Light Mode
            LumoWidgetView(entry: LumoWidgetEntry(
                date: Date(),
                searchHint: "Need an afternoon boost?",
                prompts: [
                    TimePrompt(labelKey: "widget.prompt.universeExplorer", promptKey: "widget.prompt.universeExplorer.full", id: "focus", icon: "atom"),
                    TimePrompt(labelKey: "widget.prompt.dailyLearning", promptKey: "widget.prompt.dailyLearningd.full", id: "dailylearning", icon: "book"),
                ]
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.colorScheme, .light)
            .previewDisplayName("Medium - Light Mode")
            
            // Medium - Dark Mode
            LumoWidgetView(entry: LumoWidgetEntry(
                date: Date(),
                searchHint: "Need an afternoon boost?",
                prompts: [
                    TimePrompt(labelKey: "widget.prompt.universeExplorer", promptKey: "widget.prompt.universeExplorer.full", id: "focus", icon: "atom"),
                    TimePrompt(labelKey: "widget.prompt.dailyLearning", promptKey: "widget.prompt.dailyLearningd.full", id: "dailylearning", icon: "book"),
                ]
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Medium - Dark Mode")
            
            // Medium - Tinted Mode (iOS 18)
            if #available(iOS 18.0, *) {
                LumoWidgetView(entry: LumoWidgetEntry(
                    date: Date(),
                    searchHint: "Need an afternoon boost?",
                    prompts: [
                        TimePrompt(labelKey: "widget.prompt.universeExplorer", promptKey: "widget.prompt.universeExplorer.full", id: "focus", icon: "atom"),
                        TimePrompt(labelKey: "widget.prompt.dailyLearning", promptKey: "widget.prompt.dailyLearningd.full", id: "dailylearning", icon: "book"),
                    ]
                ))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .environment(\.widgetRenderingMode, .vibrant)
                .previewDisplayName("Medium - Tinted Mode")
            }
            
            // Small - Light Mode
            LumoWidgetView(entry: LumoWidgetEntry(
                date: Date(),
                searchHint: "Need an afternoon boost?",
                prompts: []
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.colorScheme, .light)
            .previewDisplayName("Small - Light Mode")
            
            // Small - Dark Mode
            LumoWidgetView(entry: LumoWidgetEntry(
                date: Date(),
                searchHint: "Need an afternoon boost?",
                prompts: []
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Small - Dark Mode")
        }
    }
}
