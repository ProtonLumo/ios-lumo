import Foundation

/// Once you define `LocalizedStringResource` below Xcode puts related string in `Localizable.xcstrings` file.
/// The generation happens automatically when adding/removing string below. All keys are added in alphabetical order.
/// IMPORTANT: Remember about setting bundle for each key: `bundle: .module`.
enum L10n {
    enum Widget {
        static let displayName = LocalizedStringResource(
            "Lumo Quick Actions",
            bundle: .module,
            comment: "Display name of the Lumo widget shown in the widget gallery"
        )
        static let description = LocalizedStringResource(
            "Quick access to Lumo's most useful features",
            bundle: .module,
            comment: "Description of the Lumo widget shown in the widget gallery"
        )
        static let quickAccess = LocalizedStringResource(
            "Quick access to AI prompts",
            bundle: .module,
            comment: "Quick access label for widget search"
        )
        static let searchHintDefault = LocalizedStringResource(
            "Ask Lumo a question",
            bundle: .module,
            comment: "Default search hint shown in the widget when no time-specific hint applies"
        )

        enum Accessibility {
            static let openInLumo = LocalizedStringResource(
                "Open in Lumo",
                bundle: .module,
                comment: "Accessibility label for widget prompt buttons — announces the button opens content in Lumo"
            )
        }

        enum Hint {
            static let startDay = LocalizedStringResource(
                "Start your day right",
                bundle: .module,
                comment: "Widget hint shown in early morning hours (5–7am)"
            )
            static let morningProductivity = LocalizedStringResource(
                "Morning productivity",
                bundle: .module,
                comment: "Widget hint shown during morning productivity hours (7–11am)"
            )
            static let lunchBreak = LocalizedStringResource(
                "Lunch break?",
                bundle: .module,
                comment: "Widget hint shown during lunch hours (11am–2pm)"
            )
            static let afternoonBoost = LocalizedStringResource(
                "Need an afternoon boost?",
                bundle: .module,
                comment: "Widget hint shown during afternoon hours (2–5pm)"
            )
            static let windingDown = LocalizedStringResource(
                "Winding down for the day?",
                bundle: .module,
                comment: "Widget hint shown during evening wind-down hours (5–8pm)"
            )
            static let gettingReady = LocalizedStringResource(
                "Getting ready for tomorrow?",
                bundle: .module,
                comment: "Widget hint shown during night hours (8pm–midnight)"
            )
            static let troubleSleeping = LocalizedStringResource(
                "Having trouble sleeping?",
                bundle: .module,
                comment: "Widget hint shown during late night hours (midnight–5am)"
            )
        }

        enum Prompt {
            static let afternoonEnergy = LocalizedStringResource(
                "Boost your energy",
                bundle: .module,
                comment: "Short label for the afternoon energy widget prompt button"
            )
            static let afternoonPlanner = LocalizedStringResource(
                "Plan your afternoon",
                bundle: .module,
                comment: "Short label for the afternoon planner widget prompt button"
            )
            static let bedtimeStory = LocalizedStringResource(
                "Bedtime story",
                bundle: .module,
                comment: "Short label for the bedtime story widget prompt button"
            )
            static let breakfastIdeas = LocalizedStringResource(
                "Plan your breakfast",
                bundle: .module,
                comment: "Short label for the breakfast ideas widget prompt button"
            )
            static let breathingExercises = LocalizedStringResource(
                "Practice breathing",
                bundle: .module,
                comment: "Short label for the breathing exercises widget prompt button"
            )
            static let calmingMusic = LocalizedStringResource(
                "Listen to calming sounds",
                bundle: .module,
                comment: "Short label for the calming music widget prompt button"
            )
            static let calmingThoughts = LocalizedStringResource(
                "Calm your mind",
                bundle: .module,
                comment: "Short label for the calming thoughts widget prompt button"
            )
            static let coffeeBreak = LocalizedStringResource(
                "Take a mindful break",
                bundle: .module,
                comment: "Short label for the coffee break widget prompt button"
            )
            static let cognitiveBias = LocalizedStringResource(
                "Cognitive biases",
                bundle: .module,
                comment: "Short label for the cognitive bias widget prompt button"
            )
            static let cosmicPerspective = LocalizedStringResource(
                "Cosmic perspective",
                bundle: .module,
                comment: "Short label for the cosmic perspective widget prompt button"
            )
            static let creativeBoost = LocalizedStringResource(
                "Ignite your creativity",
                bundle: .module,
                comment: "Short label for the creative boost widget prompt button"
            )
            static let creativeThinking = LocalizedStringResource(
                "Spark your creativity",
                bundle: .module,
                comment: "Short label for the creative thinking widget prompt button"
            )
            static let criticalThinking = LocalizedStringResource(
                "Critical thinking",
                bundle: .module,
                comment: "Short label for the critical thinking widget prompt button"
            )
            static let dailyLearning = LocalizedStringResource(
                "Daily learning",
                bundle: .module,
                comment: "Short label for the daily learning widget prompt button"
            )
            static let dinnerRecipes = LocalizedStringResource(
                "Discover dinner ideas",
                bundle: .module,
                comment: "Short label for the dinner recipes widget prompt button"
            )
            static let diversePerspectives = LocalizedStringResource(
                "Diverse perspectives",
                bundle: .module,
                comment: "Short label for the diverse perspectives widget prompt button"
            )
            static let echoChambers = LocalizedStringResource(
                "Break echo chambers",
                bundle: .module,
                comment: "Short label for the echo chambers widget prompt button"
            )
            static let eveningReflection = LocalizedStringResource(
                "Reflect on your day",
                bundle: .module,
                comment: "Short label for the evening reflection widget prompt button"
            )
            static let eveningStretches = LocalizedStringResource(
                "Stretch before bed",
                bundle: .module,
                comment: "Short label for the evening stretches widget prompt button"
            )
            static let factChecking = LocalizedStringResource(
                "How to check facts",
                bundle: .module,
                comment: "Short label for the fact checking widget prompt button"
            )
            static let familyActivities = LocalizedStringResource(
                "Plan family time",
                bundle: .module,
                comment: "Short label for the family activities widget prompt button"
            )
            static let focusTechniques = LocalizedStringResource(
                "Sharpen your focus",
                bundle: .module,
                comment: "Short label for the focus techniques widget prompt button"
            )
            static let funFactGenerator = LocalizedStringResource(
                "Fun fact",
                bundle: .module,
                comment: "Short label for the fun fact generator widget prompt button"
            )
            static let healthyLunch = LocalizedStringResource(
                "Choose a healthy lunch",
                bundle: .module,
                comment: "Short label for the healthy lunch widget prompt button"
            )
            static let mediaLiteracy = LocalizedStringResource(
                "How to be media literate",
                bundle: .module,
                comment: "Short label for the media literacy widget prompt button"
            )
            static let misinformation = LocalizedStringResource(
                "Spot misinformation",
                bundle: .module,
                comment: "Short label for the misinformation widget prompt button"
            )
            static let morningEnergy = LocalizedStringResource(
                "Boost morning energy",
                bundle: .module,
                comment: "Short label for the morning energy widget prompt button"
            )
            static let morningExercise = LocalizedStringResource(
                "Start your workout",
                bundle: .module,
                comment: "Short label for the morning exercise widget prompt button"
            )
            static let morningMotivation = LocalizedStringResource(
                "Boost your motivation",
                bundle: .module,
                comment: "Short label for the morning motivation widget prompt button"
            )
            static let particlePlayground = LocalizedStringResource(
                "Particle playground",
                bundle: .module,
                comment: "Short label for the particle playground widget prompt button"
            )
            static let perspectiveBroadening = LocalizedStringResource(
                "Broaden perspective",
                bundle: .module,
                comment: "Short label for the perspective broadening widget prompt button"
            )
            static let phishingProtection = LocalizedStringResource(
                "Phishing protection",
                bundle: .module,
                comment: "Short label for the phishing protection widget prompt button"
            )
            static let physicsDaily = LocalizedStringResource(
                "Physics daily dose",
                bundle: .module,
                comment: "Short label for the physics daily widget prompt button"
            )
            static let physicsExplained = LocalizedStringResource(
                "Physics explained",
                bundle: .module,
                comment: "Short label for the physics explained widget prompt button"
            )
            static let privacyTips = LocalizedStringResource(
                "Privacy tips",
                bundle: .module,
                comment: "Short label for the privacy tips widget prompt button"
            )
            static let quantumCuriosity = LocalizedStringResource(
                "Quantum curiosity",
                bundle: .module,
                comment: "Short label for the quantum curiosity widget prompt button"
            )
            static let quickLunchIdeas = LocalizedStringResource(
                "Find lunch ideas",
                bundle: .module,
                comment: "Short label for the quick lunch ideas widget prompt button"
            )
            static let quickStretches = LocalizedStringResource(
                "Stretch your body",
                bundle: .module,
                comment: "Short label for the quick stretches widget prompt button"
            )
            static let quickWorkout = LocalizedStringResource(
                "Fit in a workout",
                bundle: .module,
                comment: "Short label for the quick workout widget prompt button"
            )
            static let relaxation = LocalizedStringResource(
                "Find your calm",
                bundle: .module,
                comment: "Short label for the relaxation widget prompt button"
            )
            static let relaxationTechniques = LocalizedStringResource(
                "Learn to relax",
                bundle: .module,
                comment: "Short label for the relaxation techniques widget prompt button"
            )
            static let scamSpotting = LocalizedStringResource(
                "Spot scams",
                bundle: .module,
                comment: "Short label for the scam spotting widget prompt button"
            )
            static let scientificWonder = LocalizedStringResource(
                "Scientific wonder",
                bundle: .module,
                comment: "Short label for the scientific wonder widget prompt button"
            )
            static let sleepEnvironment = LocalizedStringResource(
                "Optimize your sleep space",
                bundle: .module,
                comment: "Short label for the sleep environment widget prompt button"
            )
            static let sleepMeditation = LocalizedStringResource(
                "Meditate for sleep",
                bundle: .module,
                comment: "Short label for the sleep meditation widget prompt button"
            )
            static let sleepTips = LocalizedStringResource(
                "Improve your sleep",
                bundle: .module,
                comment: "Short label for the sleep tips widget prompt button"
            )
            static let timeManagement = LocalizedStringResource(
                "Manage your time",
                bundle: .module,
                comment: "Short label for the time management widget prompt button"
            )
            static let universeExplorer = LocalizedStringResource(
                "Universe explorer",
                bundle: .module,
                comment: "Short label for the universe explorer widget prompt button"
            )
        }

        enum PromptFull {
            static let afternoonEnergy = LocalizedStringResource(
                "What are some natural ways to boost my energy in the afternoon?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the afternoon energy suggestion"
            )
            static let bedtime = LocalizedStringResource(
                "Suggest some calming music or sounds to help me fall asleep.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the bedtime calming music suggestion"
            )
            static let bedtimeStory = LocalizedStringResource(
                "Write me a short, calming bedtime story.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the bedtime story suggestion"
            )
            static let breakfast = LocalizedStringResource(
                "Suggest a healthy and quick breakfast recipe that I can make in under 15 minutes.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the breakfast ideas suggestion"
            )
            static let breathing = LocalizedStringResource(
                "Guide me through a breathing exercise to help me relax and fall asleep.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the breathing exercises suggestion"
            )
            static let calm = LocalizedStringResource(
                "Help me with some calming thoughts to quiet my mind for sleep.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the calming thoughts suggestion"
            )
            static let coffeeBreak = LocalizedStringResource(
                "Suggest some healthy and energizing coffee break activities to refresh my mind.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the coffee break suggestion"
            )
            static let cognitiveBias = LocalizedStringResource(
                "What cognitive biases should I be aware of in my own thinking?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the cognitive bias suggestion"
            )
            static let cosmicPerspective = LocalizedStringResource(
                "Share something about the universe that puts life in perspective.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the cosmic perspective suggestion"
            )
            static let creative = LocalizedStringResource(
                "What are some techniques to boost my creative thinking for this project?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the creative thinking suggestion"
            )
            static let criticalThinking = LocalizedStringResource(
                "Teach me practical critical thinking skills I can use to evaluate information better.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the critical thinking suggestion"
            )
            static let dailyLearning = LocalizedStringResource(
                "Teach me something fascinating in 2 minutes.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the daily learning suggestion"
            )
            static let dinner = LocalizedStringResource(
                "Suggest a healthy dinner recipe that I can prepare in 30 minutes or less.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the dinner recipes suggestion"
            )
            static let diversePerspectives = LocalizedStringResource(
                "Help me understand an issue from multiple cultural and ideological perspectives.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the diverse perspectives suggestion"
            )
            static let echoChambers = LocalizedStringResource(
                "How can I break out of my information bubble and diversify my sources?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the echo chambers suggestion"
            )
            static let energy = LocalizedStringResource(
                "What are some natural ways to boost my energy in the morning without caffeine?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the morning energy suggestion"
            )
            static let environment = LocalizedStringResource(
                "How can I optimize my bedroom environment for better sleep?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the sleep environment suggestion"
            )
            static let eveningExercise = LocalizedStringResource(
                "What's a good evening workout routine that won't interfere with sleep?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the evening exercise suggestion"
            )
            static let eveningStretches = LocalizedStringResource(
                "Give me some gentle stretches I can do before bed to relax my body.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the evening stretches suggestion"
            )
            static let factChecking = LocalizedStringResource(
                "Show me effective techniques for fact-checking claims I encounter online.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the fact checking suggestion"
            )
            static let family = LocalizedStringResource(
                "Suggest some fun family activities we can do together this evening.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the family activities suggestion"
            )
            static let focus = LocalizedStringResource(
                "What are some effective techniques to regain focus during the afternoon slump?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the focus techniques suggestion"
            )
            static let funFactGenerator = LocalizedStringResource(
                "Share an interesting fact that will surprise me today.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the fun fact generator suggestion"
            )
            static let healthyLunch = LocalizedStringResource(
                "What's a balanced lunch that will give me sustained energy for the afternoon?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the healthy lunch suggestion"
            )
            static let lunch = LocalizedStringResource(
                "Recommend some quick and healthy lunch ideas that I can prepare in 20 minutes or less.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the lunch ideas suggestion"
            )
            static let mediaLiteracy = LocalizedStringResource(
                "Teach me how to identify bias and evaluate the credibility of news sources.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the media literacy suggestion"
            )
            static let meditation = LocalizedStringResource(
                "Guide me through a 5-minute bedtime meditation to calm my mind.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the sleep meditation suggestion"
            )
            static let misinformation = LocalizedStringResource(
                "How can I spot misinformation and false claims in the news and social media?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the misinformation suggestion"
            )
            static let morningExercise = LocalizedStringResource(
                "Give me a quick 10-minute morning exercise routine to energize my day.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the morning exercise suggestion"
            )
            static let motivation = LocalizedStringResource(
                "Share some motivational tips to help me start my day with enthusiasm.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the morning motivation suggestion"
            )
            static let particlePlayground = LocalizedStringResource(
                "What would happen if I could shrink down to subatomic size?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the particle playground suggestion"
            )
            static let perspectiveBroadening = LocalizedStringResource(
                "How can I actively seek out and understand viewpoints different from my own?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the perspective broadening suggestion"
            )
            static let phishingProtection = LocalizedStringResource(
                "What are the best practices to protect myself against phishing attacks?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the phishing protection suggestion"
            )
            static let physicsDaily = LocalizedStringResource(
                "Explain a fascinating physics concept to energize my mind today.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the physics daily suggestion"
            )
            static let physicsExplained = LocalizedStringResource(
                "Explain how the Large Hadron Collider works in simple terms.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the physics explained suggestion"
            )
            static let priorities = LocalizedStringResource(
                "Help me reprioritize my tasks for the rest of the day based on new information.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the priorities suggestion"
            )
            static let privacyTips = LocalizedStringResource(
                "Give me practical tips to protect my digital privacy today.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the privacy tips suggestion"
            )
            static let problem = LocalizedStringResource(
                "Help me approach this problem with a fresh perspective and find innovative solutions.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the problem solving suggestion"
            )
            static let productivity = LocalizedStringResource(
                "Share some effective productivity techniques for maintaining focus during work hours.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the productivity suggestion"
            )
            static let quantumCuriosity = LocalizedStringResource(
                "What's happening at the quantum level around me right now?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the quantum curiosity suggestion"
            )
            static let quickWorkout = LocalizedStringResource(
                "Give me a quick 10-minute workout I can do during my lunch break.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the quick workout suggestion"
            )
            static let relaxation = LocalizedStringResource(
                "What are some quick relaxation techniques I can do during my lunch break?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the relaxation suggestion"
            )
            static let relaxationTechniques = LocalizedStringResource(
                "What are some effective relaxation techniques to unwind after a busy day?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the relaxation techniques suggestion"
            )
            static let scamSpotting = LocalizedStringResource(
                "How can I spot and avoid scam texts and suspicious messages?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the scam spotting suggestion"
            )
            static let scientificWonder = LocalizedStringResource(
                "Tell me about a physics discovery that changed everything.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the scientific wonder suggestion"
            )
            static let sleep = LocalizedStringResource(
                "What are some proven techniques to help me fall asleep faster?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the sleep tips suggestion"
            )
            static let snacks = LocalizedStringResource(
                "Suggest some healthy afternoon snacks that will boost my energy without a sugar crash.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the afternoon snacks suggestion"
            )
            static let stretches = LocalizedStringResource(
                "Give me a quick stretching routine to relieve tension and improve circulation.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the stretching suggestion"
            )
            static let timeManagement = LocalizedStringResource(
                "How can I better manage my time today to accomplish my most important tasks?",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the time management suggestion"
            )
            static let universeExplorer = LocalizedStringResource(
                "Share a mind-bending fact about the cosmos and particle physics.",
                bundle: .module,
                comment: "Full prompt text sent to Lumo for the universe explorer suggestion"
            )
        }
    }
}
