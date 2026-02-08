import Foundation
import SwiftUI
import Combine

// MARK: - Questionnaire Data Models
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

// MARK: - Generated Plan Models
struct ActivityLink {
    let url: String
    let displayText: String
}

struct GeneratedActivity: Identifiable {
    let id = UUID()
    let time: String
    let name: String
    let description: String
    let links: [ActivityLink]
}

struct GeneratedDay: Identifiable {
    let id = UUID()
    let dayNumber: Int
    var activities: [GeneratedActivity]
    var isExpanded: Bool = false
}

struct GeneratedTrip {
    let cityName: String
    var days: [GeneratedDay]
}



// MARK: - View Model
class AI_Questionnaire_Model: ObservableObject {
    // Current question index (1-6)
    @Published var currentQuestion: Int = 1
    
    // Loading state
    @Published var isGenerating: Bool = false
    @Published var generationProgress: Double = 0.0
    @Published var generationStep: String = "Analyzing your destination"
    
    // Generated plan
    @Published var generatedTrip: GeneratedTrip?
    @Published var showGeneratedPlan: Bool = false
    
    // AI Generations tracking
    @Published var remainingGenerations: Int = 5 // TODO: Load from UserDefaults or backend
    private let maxGenerationsPerMonth = 5
    
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

    var selectedDays: Int {
        get { Int(numberOfDays.rounded()) }
        set { numberOfDays = Double(newValue) }
    }
    
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
    
    // Generate prompt for GPT (for future use)
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
    
    func startGeneration() {

        guard remainingGenerations > 0 else { return }
        remainingGenerations -= 1

        isGenerating = true
        generationProgress = 0.2

        Task {

            do {

                generationStep = "Creating your AI plan..."

                let prompt = generateGPTPrompt() // هذا يولد النص اللي نرسله للـ GPT

                let aiText = try await OpenAIService().generatePlan(prompt: prompt)

                print(aiText) // هنا نقدر نشوف الرد في الـ console

                // مؤقتاً خلّيها Mock
                self.createMockTrip()

                await MainActor.run {
                    self.isGenerating = false
                    self.showGeneratedPlan = true
                }

            } catch {
                print(error)

                await MainActor.run {
                    self.isGenerating = false
                }
            }
        }
    }


    
    // Reset to prepage
    func resetToPrePage() {
        showGeneratedPlan = false
        currentQuestion = 1
        generationProgress = 0.0
        isGenerating = false
    }
    
    // Create mock trip (replace with GPT response parsing later)
    private func createMockTrip() {
        let cityName = selectedCity?.name ?? "Riyadh"
        let numDays = Int(numberOfDays)
        
        var days: [GeneratedDay] = []
        
        for dayNum in 1...numDays {
            let activities = createMockActivities(for: dayNum)
            days.append(GeneratedDay(
                dayNumber: dayNum,
                activities: activities,
                isExpanded: dayNum == 1 // First day expanded
            ))
        }
        
        generatedTrip = GeneratedTrip(cityName: cityName, days: days)
    }
    
    // Create mock activities based on preferences
    private func createMockActivities(for dayNumber: Int) -> [GeneratedActivity] {
        var activities: [GeneratedActivity] = []
        
        // Cultural activity
        if selectedExperiences.contains(where: { $0.title.contains("Cultural") }) {
            activities.append(GeneratedActivity(
                time: "9:00 AM",
                name: dayNumber == 1 ? "National Museum" : "Historical District Tour",
                description: "Explore rich cultural heritage and history",
                links: [
                    ActivityLink(url: "https://maps.google.com", displayText: "https://maps.app.goo.gl/museum")
                ]
            ))
        }
        
        // Food activity
        if selectedExperiences.contains(where: { $0.title.contains("Food") }) {
            activities.append(GeneratedActivity(
                time: "1:00 PM",
                name: dayNumber == 1 ? "Billy Brunch" : "Traditional Saudi Restaurant",
                description: "Don't forget to check on the reservation",
                links: [
                    ActivityLink(url: "https://maps.google.com", displayText: "https://maps.app.goo.gl/rMtD3jZL6w2yjK9Q5B"),
                    ActivityLink(url: "https://booking.com", displayText: "Link if it was added")
                ]
            ))
        }
        
        // Adventure activity
        if selectedExperiences.contains(where: { $0.title.contains("Adventure") }) {
            activities.append(GeneratedActivity(
                time: "4:00 PM",
                name: dayNumber == 1 ? "Edge of the World" : "Desert Safari",
                description: "Breathtaking natural landscapes and adventure",
                links: [
                    ActivityLink(url: "https://maps.google.com", displayText: "https://maps.app.goo.gl/edge")
                ]
            ))
        }
        
        // Shopping activity
        if selectedExperiences.contains(where: { $0.title.contains("Shopping") }) {
            activities.append(GeneratedActivity(
                time: "6:00 PM",
                name: "Modern Shopping District",
                description: "Contemporary malls and boutiques",
                links: [
                    ActivityLink(url: "https://maps.google.com", displayText: "https://maps.app.goo.gl/mall")
                ]
            ))
        }
        
        // Default activities if none selected
        if activities.isEmpty {
            activities = [
                GeneratedActivity(
                    time: "10:00 AM",
                    name: "City Exploration",
                    description: "Discover the best of the city",
                    links: [
                        ActivityLink(url: "https://maps.google.com", displayText: "https://maps.app.goo.gl/city")
                    ]
                ),
                GeneratedActivity(
                    time: "2:00 PM",
                    name: "Local Restaurant",
                    description: "Try authentic local cuisine",
                    links: [
                        ActivityLink(url: "https://maps.google.com", displayText: "https://maps.app.goo.gl/restaurant")
                    ]
                )
            ]
        }
        
        return activities
    }
}



