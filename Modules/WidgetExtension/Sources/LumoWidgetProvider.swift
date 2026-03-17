/*
 * Copyright (c) 2025 Proton AG
 * This file is part of Proton AG and Proton Lumo.
 *
 * Proton Lumo is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Proton Lumo is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Proton Lumo.  If not, see <https://www.gnu.org/licenses/>.
 */

private enum TimePeriod {
    static let earlyMorningStart = 5
    static let earlyMorningEnd = 7
    static let morningProductivityStart = 7
    static let morningProductivityEnd = 11
    static let lunchBreakStart = 11
    static let lunchBreakEnd = 14
    static let afternoonBoostStart = 14
    static let afternoonBoostEnd = 17
    static let eveningWindDownStart = 17
    static let eveningWindDownEnd = 20
    static let nightTimeStart = 20
    static let nightTimeEnd = 24
}

func getTimeSensitiveSuggestion(hour: Int, prompts: Int) -> (hint: String, prompts: [TimePrompt]) {
    WidgetLogger.shared.log("Getting suggestions for hour: \(hour)", isDebugOnly: true)

    if hour >= TimePeriod.earlyMorningStart && hour < TimePeriod.earlyMorningEnd {
        // Early morning prompts
        let earlyMorningPrompts = [
            TimePrompt(label: L10n.Widget.Prompt.breakfastIdeas, prompt: L10n.Widget.PromptFull.breakfast, id: "breakfast", icon: "sunrise"),
            TimePrompt(label: L10n.Widget.Prompt.morningExercise, prompt: L10n.Widget.PromptFull.morningExercise, id: "morning_exercise", icon: "figure.run"),
            TimePrompt(label: L10n.Widget.Prompt.funFactGenerator, prompt: L10n.Widget.PromptFull.funFactGenerator, id: "fun_fact", icon: "lightbulb"),
            TimePrompt(label: L10n.Widget.Prompt.morningEnergy, prompt: L10n.Widget.PromptFull.energy, id: "energy", icon: "flame"),
            TimePrompt(label: L10n.Widget.Prompt.privacyTips, prompt: L10n.Widget.PromptFull.privacyTips, id: "privacy_tips", icon: "lock.shield"),
        ]

        return (
            hint: String(localized: L10n.Widget.Hint.startDay),
            prompts: Array(earlyMorningPrompts.shuffled().prefix(prompts))
        )
    } else if hour >= TimePeriod.morningProductivityStart && hour < TimePeriod.morningProductivityEnd {
        // Morning productivity prompts
        let morningProductivityPrompts = [
            TimePrompt(label: L10n.Widget.Prompt.timeManagement, prompt: L10n.Widget.PromptFull.timeManagement, id: "time", icon: "clock"),
            TimePrompt(label: L10n.Widget.Prompt.diversePerspectives, prompt: L10n.Widget.PromptFull.diversePerspectives, id: "diverse_perspectives", icon: "person.3"),
            TimePrompt(label: L10n.Widget.Prompt.physicsDaily, prompt: L10n.Widget.PromptFull.physicsDaily, id: "physics_daily", icon: "atom"),
            TimePrompt(label: L10n.Widget.Prompt.creativeThinking, prompt: L10n.Widget.PromptFull.creative, id: "creative", icon: "paintbrush"),
            TimePrompt(label: L10n.Widget.Prompt.echoChambers, prompt: L10n.Widget.PromptFull.echoChambers, id: "echo_chambers", icon: "bubble.left.and.bubble.right"),
            TimePrompt(label: L10n.Widget.Prompt.quantumCuriosity, prompt: L10n.Widget.PromptFull.quantumCuriosity, id: "quantum_curiosity", icon: "sparkles"),
        ]

        return (
            hint: String(localized: L10n.Widget.Hint.morningProductivity),
            prompts: Array(morningProductivityPrompts.shuffled().prefix(prompts))
        )
    } else if hour >= TimePeriod.lunchBreakStart && hour < TimePeriod.lunchBreakEnd {
        // Lunch break prompts
        let lunchBreakPrompts = [
            TimePrompt(label: L10n.Widget.Prompt.quickLunchIdeas, prompt: L10n.Widget.PromptFull.lunch, id: "lunch", icon: "fork.knife"),
            TimePrompt(label: L10n.Widget.Prompt.universeExplorer, prompt: L10n.Widget.PromptFull.universeExplorer, id: "universe_explorer", icon: "globe"),
            TimePrompt(label: L10n.Widget.Prompt.physicsExplained, prompt: L10n.Widget.PromptFull.physicsExplained, id: "physics_explained", icon: "brain.head.profile"),
            TimePrompt(label: L10n.Widget.Prompt.healthyLunch, prompt: L10n.Widget.PromptFull.healthyLunch, id: "healthy_lunch", icon: "leaf"),
            TimePrompt(label: L10n.Widget.Prompt.relaxation, prompt: L10n.Widget.PromptFull.relaxation, id: "relax", icon: "sparkles"),
        ]

        return (
            hint: String(localized: L10n.Widget.Hint.lunchBreak),
            prompts: Array(lunchBreakPrompts.shuffled().prefix(prompts))
        )
    } else if hour >= TimePeriod.afternoonBoostStart && hour < TimePeriod.afternoonBoostEnd {
        // Afternoon boost prompts
        let afternoonBoostPrompts = [
            TimePrompt(label: L10n.Widget.Prompt.focusTechniques, prompt: L10n.Widget.PromptFull.focus, id: "focus", icon: "brain.head.profile"),
            TimePrompt(label: L10n.Widget.Prompt.mediaLiteracy, prompt: L10n.Widget.PromptFull.mediaLiteracy, id: "media_literacy", icon: "newspaper"),
            TimePrompt(label: L10n.Widget.Prompt.quickStretches, prompt: L10n.Widget.PromptFull.stretches, id: "stretches", icon: "figure.flexibility"),
            TimePrompt(label: L10n.Widget.Prompt.scientificWonder, prompt: L10n.Widget.PromptFull.scientificWonder, id: "scientific_wonder", icon: "star"),
            TimePrompt(label: L10n.Widget.Prompt.cognitiveBias, prompt: L10n.Widget.PromptFull.cognitiveBias, id: "cognitive_bias", icon: "brain"),
            TimePrompt(label: L10n.Widget.Prompt.particlePlayground, prompt: L10n.Widget.PromptFull.particlePlayground, id: "particle_playground", icon: "atom"),
            TimePrompt(label: L10n.Widget.Prompt.dailyLearning, prompt: L10n.Widget.PromptFull.dailyLearning, id: "daily_learning", icon: "book"),
            TimePrompt(label: L10n.Widget.Prompt.factChecking, prompt: L10n.Widget.PromptFull.factChecking, id: "fact_checking", icon: "magnifyingglass"),
        ]

        return (
            hint: String(localized: L10n.Widget.Hint.afternoonBoost),
            prompts: Array(afternoonBoostPrompts.shuffled().prefix(prompts))
        )
    } else if hour >= TimePeriod.eveningWindDownStart && hour < TimePeriod.eveningWindDownEnd {
        // Evening wind-down prompts
        let eveningWindDownPrompts = [
            TimePrompt(label: L10n.Widget.Prompt.dinnerRecipes, prompt: L10n.Widget.PromptFull.dinner, id: "dinner", icon: "cooktop"),
            TimePrompt(label: L10n.Widget.Prompt.cosmicPerspective, prompt: L10n.Widget.PromptFull.cosmicPerspective, id: "cosmic_perspective", icon: "globe"),
            TimePrompt(label: L10n.Widget.Prompt.familyActivities, prompt: L10n.Widget.PromptFull.family, id: "family", icon: "person.3"),
            TimePrompt(label: L10n.Widget.Prompt.scamSpotting, prompt: L10n.Widget.PromptFull.scamSpotting, id: "scam_spotting", icon: "shield"),
            TimePrompt(label: L10n.Widget.Prompt.relaxationTechniques, prompt: L10n.Widget.PromptFull.relaxationTechniques, id: "relaxation", icon: "sparkles"),
            TimePrompt(label: L10n.Widget.Prompt.bedtimeStory, prompt: L10n.Widget.PromptFull.bedtimeStory, id: "bedtime_story", icon: "book"),
        ]

        return (
            hint: String(localized: L10n.Widget.Hint.windingDown),
            prompts: Array(eveningWindDownPrompts.shuffled().prefix(prompts))
        )
    } else if hour >= TimePeriod.nightTimeStart && hour < TimePeriod.nightTimeEnd {
        // Night time prompts
        let nightTimePrompts = [
            TimePrompt(label: L10n.Widget.Prompt.sleepTips, prompt: L10n.Widget.PromptFull.sleep, id: "sleep", icon: "moon.stars"),
            TimePrompt(label: L10n.Widget.Prompt.phishingProtection, prompt: L10n.Widget.PromptFull.phishingProtection, id: "phishing_protection", icon: "shield.checkered"),
            TimePrompt(label: L10n.Widget.Prompt.eveningStretches, prompt: L10n.Widget.PromptFull.eveningStretches, id: "stretches", icon: "figure.flexibility"),
            TimePrompt(label: L10n.Widget.Prompt.sleepEnvironment, prompt: L10n.Widget.PromptFull.environment, id: "environment", icon: "house"),
        ]

        return (
            hint: String(localized: L10n.Widget.Hint.gettingReady),
            prompts: Array(nightTimePrompts.shuffled().prefix(prompts))
        )
    } else {
        // Late night prompts
        let lateNightPrompts = [
            TimePrompt(label: L10n.Widget.Prompt.sleepMeditation, prompt: L10n.Widget.PromptFull.meditation, id: "meditation", icon: "moon.zzz"),
            TimePrompt(label: L10n.Widget.Prompt.criticalThinking, prompt: L10n.Widget.PromptFull.criticalThinking, id: "critical_thinking", icon: "brain.head.profile"),
            TimePrompt(label: L10n.Widget.Prompt.breathingExercises, prompt: L10n.Widget.PromptFull.breathing, id: "breathing", icon: "wind"),
            TimePrompt(label: L10n.Widget.Prompt.misinformation, prompt: L10n.Widget.PromptFull.misinformation, id: "misinformation", icon: "checkmark.shield"),
            TimePrompt(label: L10n.Widget.Prompt.sleepEnvironment, prompt: L10n.Widget.PromptFull.environment, id: "environment", icon: "house"),
            TimePrompt(label: L10n.Widget.Prompt.perspectiveBroadening, prompt: L10n.Widget.PromptFull.perspectiveBroadening, id: "perspective_broadening", icon: "eye"),
            TimePrompt(label: L10n.Widget.Prompt.calmingMusic, prompt: L10n.Widget.PromptFull.bedtime, id: "bedtime", icon: "music.note"),
        ]

        return (
            hint: String(localized: L10n.Widget.Hint.troubleSleeping),
            prompts: Array(lateNightPrompts.shuffled().prefix(prompts))
        )
    }
}
