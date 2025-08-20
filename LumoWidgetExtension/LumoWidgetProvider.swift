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
    static let lateNightStart = 0
    static let lateNightEnd = 5
}


func getTimeSensitiveSuggestion(hour: Int) -> (hint: String, prompts: [TimePrompt]) {
    WidgetLogger.shared.log("Getting suggestions for hour: \(hour)", isDebugOnly: true)
    
    if hour >= TimePeriod.earlyMorningStart && hour < TimePeriod.earlyMorningEnd {
        // Early morning prompts
        let earlyMorningPrompts = [
            TimePrompt(labelKey: "widget.prompt.breakfastIdeas", promptKey: "widget.prompt.breakfast.full", id: "breakfast", icon: "sunrise"),
            TimePrompt(labelKey: "widget.prompt.morningExercise", promptKey: "widget.prompt.morningExercise.full", id: "morning_exercise", icon: "figure.run"),
            TimePrompt(labelKey: "widget.prompt.funFactGenerator", promptKey: "widget.prompt.funFactGenerator.full", id: "fun_fact", icon: "lightbulb"),
            TimePrompt(labelKey: "widget.prompt.morningEnergy", promptKey: "widget.prompt.energy.full", id: "energy", icon: "flame"),
            TimePrompt(labelKey: "widget.prompt.privacyTips", promptKey: "widget.prompt.privacyTips.full", id: "privacy_tips", icon: "lock.shield"),
        ]
        
        return (
            hint: String(localized: "widget.hint.startDay"),
            prompts: Array(earlyMorningPrompts.shuffled().prefix(2))
        )
    }
    
    else if hour >= TimePeriod.morningProductivityStart && hour < TimePeriod.morningProductivityEnd {
        // Morning productivity prompts
        let morningProductivityPrompts = [
            TimePrompt(labelKey: "widget.prompt.timeManagement", promptKey: "widget.prompt.timeManagement.full", id: "time", icon: "clock"),
            TimePrompt(labelKey: "widget.prompt.diversePerspectives", promptKey: "widget.prompt.diversePerspectives.full", id: "diverse_perspectives", icon: "person.3"),
            TimePrompt(labelKey: "widget.prompt.physicsDaily", promptKey: "widget.prompt.physicsDaily.full", id: "physics_daily", icon: "atom"),
            TimePrompt(labelKey: "widget.prompt.creativeThinking", promptKey: "widget.prompt.creative.full", id: "creative", icon: "paintbrush"),
            TimePrompt(labelKey: "widget.prompt.echoChambers", promptKey: "widget.prompt.echoChambers.full", id: "echo_chambers", icon: "bubble.left.and.bubble.right"),
            TimePrompt(labelKey: "widget.prompt.quantumCuriosity", promptKey: "widget.prompt.quantumCuriosity.full", id: "quantum_curiosity", icon: "sparkles")
        ]
        
        return (
            hint: String(localized: "widget.hint.morningProductivity"),
            prompts: Array(morningProductivityPrompts.shuffled().prefix(2))
        )
    }
    
    else if hour >= TimePeriod.lunchBreakStart && hour < TimePeriod.lunchBreakEnd {
        // Lunch break prompts
        let lunchBreakPrompts = [
            TimePrompt(labelKey: "widget.prompt.quickLunchIdeas", promptKey: "widget.prompt.lunch.full", id: "lunch", icon: "fork.knife"),
            TimePrompt(labelKey: "widget.prompt.universeExplorer", promptKey: "widget.prompt.universeExplorer.full", id: "universe_explorer", icon: "globe"),
            TimePrompt(labelKey: "widget.prompt.physicsExplained", promptKey: "widget.prompt.physicsExplained.full", id: "physics_explained", icon: "brain.head.profile"),
            TimePrompt(labelKey: "widget.prompt.healthyLunch", promptKey: "widget.prompt.healthyLunch.full", id: "healthy_lunch", icon: "leaf"),
            TimePrompt(labelKey: "widget.prompt.relaxation", promptKey: "widget.prompt.relaxation.full", id: "relax", icon: "sparkles")
        ]
        
        return (
            hint: String(localized: "widget.hint.lunchBreak"),
            prompts: Array(lunchBreakPrompts.shuffled().prefix(2))
        )
    }
    
    else if hour >= TimePeriod.afternoonBoostStart && hour < TimePeriod.afternoonBoostEnd {
        // Afternoon boost prompts
        let afternoonBoostPrompts = [
            TimePrompt(labelKey: "widget.prompt.focusTechniques", promptKey: "widget.prompt.focus.full", id: "focus", icon: "brain.head.profile"),
            TimePrompt(labelKey: "widget.prompt.mediaLiteracy", promptKey: "widget.prompt.mediaLiteracy.full", id: "media_literacy", icon: "newspaper"),
            TimePrompt(labelKey: "widget.prompt.quickStretches", promptKey: "widget.prompt.stretches.full", id: "stretches", icon: "figure.flexibility"),
            TimePrompt(labelKey: "widget.prompt.scientificWonder", promptKey: "widget.prompt.scientificWonder.full", id: "scientific_wonder", icon: "star"),
            TimePrompt(labelKey: "widget.prompt.cognitiveBias", promptKey: "widget.prompt.cognitiveBias.full", id: "cognitive_bias", icon: "brain"),
            TimePrompt(labelKey: "widget.prompt.particlePlayground", promptKey: "widget.prompt.particlePlayground.full", id: "particle_playground", icon: "atom"),
            TimePrompt(labelKey: "widget.prompt.dailyLearning", promptKey: "widget.prompt.dailyLearning.full", id: "daily_learning", icon: "book"),
            TimePrompt(labelKey: "widget.prompt.factChecking", promptKey: "widget.prompt.factChecking.full", id: "fact_checking", icon: "magnifyingglass")
        ]
        
        return (
            hint: String(localized: "widget.hint.afternoonBoost"),
            prompts: Array(afternoonBoostPrompts.shuffled().prefix(2))
        )
    }
    
    else if hour >= TimePeriod.eveningWindDownStart && hour < TimePeriod.eveningWindDownEnd {
        // Evening wind-down prompts
        let eveningWindDownPrompts = [
            TimePrompt(labelKey: "widget.prompt.dinnerRecipes", promptKey: "widget.prompt.dinner.full", id: "dinner", icon: "cooktop"),
            TimePrompt(labelKey: "widget.prompt.cosmicPerspective", promptKey: "widget.prompt.cosmicPerspective.full", id: "cosmic_perspective", icon: "globe"),
            TimePrompt(labelKey: "widget.prompt.familyActivities", promptKey: "widget.prompt.family.full", id: "family", icon: "person.3"),
            TimePrompt(labelKey: "widget.prompt.scamSpotting", promptKey: "widget.prompt.scamSpotting.full", id: "scam_spotting", icon: "shield"),
            TimePrompt(labelKey: "widget.prompt.relaxationTechniques", promptKey: "widget.prompt.relaxationTechniques.full", id: "relaxation", icon: "sparkles"),
            TimePrompt(labelKey: "widget.prompt.bedtimeStory", promptKey: "widget.prompt.bedtimeStory.full", id: "bedtime_story", icon: "book")
        ]
        
        return (
            hint: String(localized: "widget.hint.windingDown"),
            prompts: Array(eveningWindDownPrompts.shuffled().prefix(2))
        )
    }
    
    else if hour >= TimePeriod.nightTimeStart && hour < TimePeriod.nightTimeEnd {
        // Night time prompts
        let nightTimePrompts = [
            TimePrompt(labelKey: "widget.prompt.sleepTips", promptKey: "widget.prompt.sleep.full", id: "sleep", icon: "moon.stars"),
            TimePrompt(labelKey: "widget.prompt.phishingProtection", promptKey: "widget.prompt.phishingProtection.full", id: "phishing_protection", icon: "shield.checkered"),
            TimePrompt(labelKey: "widget.prompt.eveningStretches", promptKey: "widget.prompt.eveningStretches.full", id: "stretches", icon: "figure.flexibility"),
            TimePrompt(labelKey: "widget.prompt.sleepEnvironment", promptKey: "widget.prompt.environment.full", id: "environment", icon: "house")
        ]
        
        return (
            hint: String(localized: "widget.hint.gettingReady"),
            prompts: Array(nightTimePrompts.shuffled().prefix(2))
        )
    }
    
    else {
        // Late night prompts
        let lateNightPrompts = [
            TimePrompt(labelKey: "widget.prompt.sleepMeditation", promptKey: "widget.prompt.meditation.full", id: "meditation", icon: "moon.zzz"),
            TimePrompt(labelKey: "widget.prompt.criticalThinking", promptKey: "widget.prompt.criticalThinking.full", id: "critical_thinking", icon: "brain.head.profile"),
            TimePrompt(labelKey: "widget.prompt.breathingExercises", promptKey: "widget.prompt.breathing.full", id: "breathing", icon: "wind"),
            TimePrompt(labelKey: "widget.prompt.misinformation", promptKey: "widget.prompt.misinformation.full", id: "misinformation", icon: "checkmark.shield"),
            TimePrompt(labelKey: "widget.prompt.sleepEnvironment", promptKey: "widget.prompt.environment.full", id: "environment", icon: "house"),
            TimePrompt(labelKey: "widget.prompt.perspectiveBroadening", promptKey: "widget.prompt.perspectiveBroadening.full", id: "perspective_broadening", icon: "eye"),
            TimePrompt(labelKey: "widget.prompt.calmingMusic", promptKey: "widget.prompt.bedtime.full", id: "bedtime", icon: "music.note")
        ]
        
        return (
            hint: String(localized: "widget.hint.troubleSleeping"),
            prompts: Array(lateNightPrompts.shuffled().prefix(2))
        )
    }
}
