import Foundation
import SwiftUI
import Combine

// MARK: - Data Models
struct TravelCompanion: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
}

struct ExperienceType: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
}

struct City: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

struct TravelPace: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let tags: [String]
}

struct BudgetOption: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let range: String
}

// MARK: - View Model
class AI_Questionnaire_Model: ObservableObject {
    // Current question index (1-6)
    @Published var currentQuestion: Int = 1
    
    // Loading state
    @Published var isGenerating: Bool = false
    @Published var generationProgress: Double = 0.0
    @Published var generationStep: String = "Analyzing your destination"
    
    // Q1: City Selection
    @Published var selectedCity: City?
    let cities = [
        City(name: "Riyadh"),
        City(name: "Jeddah"),
        City(name: "Abha")
    ]
    
    // Q2: Experience Types (Multiple Selection)
    @Published var selectedExperiences: Set<ExperienceType> = []
    let experiences = [
        ExperienceType(title: "Cultural &\nHistorical", description: "Museums, heritage sites, and monuments"),
        ExperienceType(title: "Adventure &\nNature", description: "Hiking, deserts, and natural landscapes"),
        ExperienceType(title: "Relaxation", description: "Serenity, tranquility, and wellness"),
        ExperienceType(title: "Shopping &\nModern", description: "Malls, boutiques, urban attractions"),
        ExperienceType(title: "Food &\nCulinary", description: "Local cuisine, food tours, and dining")
    ]
    
    // Q3: Travel Companions
    @Published var selectedCompanion: TravelCompanion?
    let companions = [
        TravelCompanion(title: "Solo", description: "Independent exploration at your own pace"),
        TravelCompanion(title: "Couple", description: "Romantic experiences and intimate settings"),
        TravelCompanion(title: "Family with Children", description: "Kid-friendly activities and family attractions"),
        TravelCompanion(title: "Friends Group", description: "Social activities and group adventures")
    ]
    
    // Q4: Budget
    @Published var selectedBudget: BudgetOption?
    let budgets = [
        BudgetOption(title: "Budget-Friendly", range: "300-600 SAR/day"),
        BudgetOption(title: "Mid-Range", range: "600-1200 SAR/day"),
        BudgetOption(title: "Luxury", range: "1,200+ SAR/day")
    ]
    
    // Q5: Number of days
    @Published var numberOfDays: Double = 1
    let maxDays: Double = 7
    
    // Q6: Travel Pace
    @Published var selectedPace: TravelPace?
    let paces = [
        TravelPace(title: "Relaxed", description: "Take it slow and enjoy plenty of downtime between activities. Perfect for soaking in the atmosphere.", tags: ["2-3 activities/day", "Lots of free time", "Flexible schedule"]),
        TravelPace(title: "Moderate", description: "Balanced approach with structured planning time to rest. The sweet spot for most travelers.", tags: ["4-5 activities/day", "Balanced schedule", "Some flexibility"]),
        TravelPace(title: "Packed", description: "Maximize every moment with back-to-back experiences. See and do as much as possible in limited time.", tags: ["6+ activities/day", "Full schedule", "Action-packed"])
    ]
    
    // Navigation
    func goToNextQuestion() {
        if currentQuestion < 6 {
            currentQuestion += 1
        }
    }
    
    func goToPreviousQuestion() {
        if currentQuestion > 1 {
            currentQuestion -= 1
        }
    }
    
    // Validation
    func isCurrentQuestionValid() -> Bool {
        switch currentQuestion {
        case 1:
            return selectedCity != nil
        case 2:
            return !selectedExperiences.isEmpty
        case 3:
            return selectedCompanion != nil
        case 4:
            return selectedBudget != nil
        case 5:
            return true // Days always has a value
        case 6:
            return selectedPace != nil
        default:
            return false
        }
    }
    
    // Generate prompt for GPT
    func generateGPTPrompt() -> String {
        var prompt = "Generate a personalized travel itinerary with the following preferences:\n\n"
        
        if let city = selectedCity {
            prompt += "Destination: \(city.name), Saudi Arabia\n"
        }
        
        if !selectedExperiences.isEmpty {
            prompt += "Interests: \(selectedExperiences.map { $0.title.replacingOccurrences(of: "\n", with: " ") }.joined(separator: ", "))\n"
        }
        
        if let companion = selectedCompanion {
            prompt += "Traveling with: \(companion.title)\n"
        }
        
        if let budget = selectedBudget {
            prompt += "Budget: \(budget.title) (\(budget.range))\n"
        }
        
        prompt += "Duration: \(Int(numberOfDays)) day(s)\n"
        
        if let pace = selectedPace {
            prompt += "Travel Pace: \(pace.title)\n"
        }
        
        return prompt
    }
    
    // Start generation with animated progress
    func startGeneration() {
        isGenerating = true
        generationProgress = 0.0
        
        let steps = [
            (progress: 0.2, step: "Analyzing your destination"),
            (progress: 0.4, step: "Gathering experiences"),
            (progress: 0.6, step: "Optimizing your itinerary"),
            (progress: 0.8, step: "Personalizing recommendations"),
            (progress: 1.0, step: "Finalizing your journey")
        ]
        
        var currentStepIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            if currentStepIndex < steps.count {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.generationProgress = steps[currentStepIndex].progress
                    self.generationStep = steps[currentStepIndex].step
                }
                currentStepIndex += 1
            } else {
                timer.invalidate()
                // TODO: Navigate to results page or call GPT API
                // For now, keep showing 100%
            }
        }
    }
}
