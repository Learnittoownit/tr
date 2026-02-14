import Foundation
import SwiftUI
import Combine
import SwiftData

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
    @Published var generationStep: String = "Analyzing your preferences..."

    // Generated plan
    @Published var generatedTrip: GeneratedTrip?
    @Published var showGeneratedPlan: Bool = false

    // Error state
    @Published var generationFailed: Bool = false
    @Published var generationErrorMessage: String = ""

    // MARK: - Ironclad Monthly Generations Counter
    // We use THREE separate UserDefaults keys to make this bulletproof:
    // 1. The remaining count
    // 2. The month-year it was last set
    // 3. A "has been initialized" flag so first launch works correctly
    private let udGenerationsKey    = "ai_remaining_generations_v2"
    private let udMonthYearKey      = "ai_last_month_year_v2"
    private let udInitializedKey    = "ai_counter_initialized_v2"
    private let maxGenerationsPerMonth = 5

    @Published var remainingGenerations: Int = 5 {
        didSet {
            // ALWAYS save to UserDefaults the instant it changes
            UserDefaults.standard.set(remainingGenerations, forKey: udGenerationsKey)
            UserDefaults.standard.synchronize() // force immediate write to disk
            print("💾 Saved remainingGenerations = \(remainingGenerations)")
        }
    }

    // MARK: - Load or reset — called ONCE at init
    private func loadOrResetGenerations() {

        let calendar = Calendar.current
        let now = Date()
        let currentMonth     = calendar.component(.month, from: now)
        let currentYear      = calendar.component(.year,  from: now)
        let currentMonthYear = "\(currentYear)-\(currentMonth)"

        let savedMonthYear  = UserDefaults.standard.string(forKey: udMonthYearKey) ?? ""
        let isInitialized   = UserDefaults.standard.bool(forKey: udInitializedKey)

        if !isInitialized {
            // ── Very first launch ever ──────────────────────────────────
            print("🆕 First launch — initializing generations to \(maxGenerationsPerMonth)")
            _remainingGenerations = Published(initialValue: maxGenerationsPerMonth)
            UserDefaults.standard.set(maxGenerationsPerMonth, forKey: udGenerationsKey)
            UserDefaults.standard.set(currentMonthYear,       forKey: udMonthYearKey)
            UserDefaults.standard.set(true,                   forKey: udInitializedKey)
            UserDefaults.standard.synchronize()

        } else if savedMonthYear != currentMonthYear {
            // ── New month — reset counter ───────────────────────────────
            print("🔄 New month (\(currentMonthYear)) — resetting generations to \(maxGenerationsPerMonth)")
            _remainingGenerations = Published(initialValue: maxGenerationsPerMonth)
            UserDefaults.standard.set(maxGenerationsPerMonth, forKey: udGenerationsKey)
            UserDefaults.standard.set(currentMonthYear,       forKey: udMonthYearKey)
            UserDefaults.standard.synchronize()

        } else {
            // ── Same month — load EXACT saved value, even if it's 0 ────
            let saved = UserDefaults.standard.integer(forKey: udGenerationsKey)
            print("📦 Same month (\(currentMonthYear)) — loaded saved value: \(saved)")
            _remainingGenerations = Published(initialValue: saved)
            // Do NOT touch UserDefaults here — just read it
        }
    }

    // MARK: - Q1: City
    @Published var selectedCity: City?
    let cities = [
        City(name: "Riyadh"),
        City(name: "Jeddah"),
        City(name: "Abha")
    ]

    // MARK: - Q2: Experience Types (Multiple Selection)
    @Published var selectedExperiences: Set<ExperienceType> = []
    let experiences = [
        ExperienceType(title: "Cultural &\nHistorical", description: "Museums, heritage sites, and monuments"),
        ExperienceType(title: "Adventure &\nNature",    description: "Hiking, deserts, and natural landscapes"),
        ExperienceType(title: "Relaxation",             description: "Serenity, tranquility, and wellness"),
        ExperienceType(title: "Shopping &\nModern",     description: "Malls, boutiques, urban attractions"),
        ExperienceType(title: "Food &\nCulinary",       description: "Local cuisine, food tours, and dining")
    ]

    // MARK: - Q3: Travel Companions
    @Published var selectedCompanion: TravelCompanion?
    let companions = [
        TravelCompanion(title: "Solo",                 description: "Independent exploration at your own pace"),
        TravelCompanion(title: "Couple",               description: "Romantic experiences and intimate settings"),
        TravelCompanion(title: "Family with Children", description: "Kid-friendly activities and family attractions"),
        TravelCompanion(title: "Friends Group",        description: "Social activities and group adventures")
    ]

    // MARK: - Q4: Budget
    @Published var selectedBudget: BudgetOption?
    let budgets = [
        BudgetOption(title: "Budget-Friendly", range: "300-600 SAR/day"),
        BudgetOption(title: "Mid-Range",       range: "600-1200 SAR/day"),
        BudgetOption(title: "Luxury",          range: "1,200+ SAR/day")
    ]

    // MARK: - Q5: Number of Days
    @Published var numberOfDays: Double = 1
    let maxDays: Double = 7

    var selectedDays: Int {
        get { Int(numberOfDays.rounded()) }
        set { numberOfDays = Double(newValue) }
    }

    // MARK: - Q6: Travel Pace
    @Published var selectedPace: TravelPace?
    let paces = [
        TravelPace(
            title: "Relaxed",
            description: "Take it slow and enjoy plenty of downtime between activities. Perfect for soaking in the atmosphere.",
            tags: ["2-3 activities/day", "Lots of free time", "Flexible schedule"]
        ),
        TravelPace(
            title: "Moderate",
            description: "Balanced approach with structured planning time to rest. The sweet spot for most travelers.",
            tags: ["4-5 activities/day", "Balanced schedule", "Some flexibility"]
        ),
        TravelPace(
            title: "Packed",
            description: "Maximize every moment with back-to-back experiences. See and do as much as possible in limited time.",
            tags: ["6+ activities/day", "Full schedule", "Action-packed"]
        )
    ]

    // MARK: - Init
    init() {
        loadOrResetGenerations()
    }

    // MARK: - Navigation
    func goToNextQuestion() {
        if currentQuestion < 6 { currentQuestion += 1 }
    }

    func goToPreviousQuestion() {
        if currentQuestion > 1 { currentQuestion -= 1 }
    }

    // MARK: - Validation
    func isCurrentQuestionValid() -> Bool {
        switch currentQuestion {
        case 1: return selectedCity != nil
        case 2: return !selectedExperiences.isEmpty
        case 3: return selectedCompanion != nil
        case 4: return selectedBudget != nil
        case 5: return true
        case 6: return selectedPace != nil
        default: return false
        }
    }

    // MARK: - Build GPT prompt
    func generateGPTPrompt() -> String {
        var parts: [String] = []

        if let city = selectedCity {
            parts.append("Destination: \(city.name), Saudi Arabia")
        }
        if !selectedExperiences.isEmpty {
            let list = selectedExperiences
                .map { $0.title.replacingOccurrences(of: "\n", with: " ") }
                .joined(separator: ", ")
            parts.append("Interests: \(list)")
        }
        if let companion = selectedCompanion {
            parts.append("Traveling with: \(companion.title)")
        }
        if let budget = selectedBudget {
            parts.append("Daily budget per person: \(budget.title) (\(budget.range))")
        }
        parts.append("Trip duration: \(Int(numberOfDays)) day(s)")
        if let pace = selectedPace {
            parts.append("Preferred pace: \(pace.title) — \(pace.description)")
        }

        return parts.joined(separator: "\n")
    }

    // MARK: - Generate Plan
    func startGeneration() {
        // Double-check before deducting
        guard remainingGenerations > 0 else {
            print("🚫 No generations remaining this month")
            return
        }

        // Deduct immediately and save to disk
        remainingGenerations -= 1
        print("🔢 Generation used. Remaining: \(remainingGenerations)")

        isGenerating = true
        generationFailed = false
        generationProgress = 0.0
        generationStep = "Analyzing your preferences..."

        Task {
            do {
                await animateTo(progress: 0.20, step: "Analyzing your preferences...", duration: 0.6)
                await animateTo(progress: 0.45, step: "Crafting your itinerary...",    duration: 0.8)

                let prompt  = generateGPTPrompt()
                let service = OpenAIService()

                print("🚀 Sending to OpenAI:\n\(prompt)\n")

                let aiText = try await service.generatePlan(prompt: prompt)

                print("✅ AI response received")

                await animateTo(progress: 0.75, step: "Personalizing your plan...", duration: 0.6)

                let trip = try service.parseGeneratedTrip(from: aiText)

                await animateTo(progress: 1.0, step: "Almost ready!", duration: 0.5)
                try? await Task.sleep(nanoseconds: 500_000_000)

                await MainActor.run {
                    self.generatedTrip     = trip
                    self.isGenerating      = false
                    self.showGeneratedPlan = true
                }

            } catch {
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("❌ GENERATION FAILED")
                print("❌ Error: \(error)")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

                await MainActor.run {
                    self.isGenerating           = false
                    self.generationFailed       = true
                    self.generationErrorMessage = error.localizedDescription
                    // Only refund if it was a network/technical failure
                    // NOT if it was a valid API call that just returned an error
                    if let urlError = error as? URLError {
                        print("🔁 Network error — refunding generation")
                        self.remainingGenerations += 1
                    }
                }
            }
        }
    }

    // MARK: - Smooth progress animation
    @MainActor
    private func animateTo(progress target: Double, step: String, duration: Double) async {
        withAnimation(.easeInOut(duration: duration)) {
            self.generationProgress = target
            self.generationStep     = step
        }
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }

    // MARK: - Reset
    func resetToPrePage() {
        showGeneratedPlan  = false
        currentQuestion    = 1
        generationProgress = 0.0
        isGenerating       = false
        generationFailed   = false
    }

    func resetAllAnswers() {
        currentQuestion        = 1
        isGenerating           = false
        generationProgress     = 0.0
        generationStep         = "Analyzing your preferences..."
        showGeneratedPlan      = false
        generatedTrip          = nil
        generationFailed       = false
        generationErrorMessage = ""

        selectedCity = nil
        selectedExperiences.removeAll()
        selectedCompanion = nil
        selectedBudget    = nil
        numberOfDays      = 1
        selectedPace      = nil
    }

    // MARK: - Save to Journal (SwiftData)
    func saveToJournal(modelContext: ModelContext) -> Trip? {
        guard let generatedTrip = generatedTrip else {
            print("❌ No generated trip to save")
            return nil
        }

        print("🔵 Saving to SwiftData...")

        let trip = Trip(
            name: "\(generatedTrip.cityName) Journey",
            startDate: Date(),
            endDate: Calendar.current.date(
                byAdding: .day,
                value: generatedTrip.days.count - 1,
                to: Date()
            ) ?? Date(),
            colorTheme: Trip.availableThemes.randomElement() ?? "#FFB5A0"
        )

        var swiftDataDays: [Day] = []

        for (index, generatedDay) in generatedTrip.days.enumerated() {
            let dayDate = Calendar.current.date(
                byAdding: .day, value: index, to: Date()
            ) ?? Date()

            let day = Day(date: dayDate, dayNumber: generatedDay.dayNumber)
            var swiftDataActivities: [Activity] = []

            for generatedActivity in generatedDay.activities {
                let timeComponents = parseTime(generatedActivity.time)
                let activityTime = Calendar.current.date(
                    bySettingHour: timeComponents.hour,
                    minute: timeComponents.minute,
                    second: 0,
                    of: dayDate
                ) ?? dayDate

                let activity = Activity(
                    name: generatedActivity.name,
                    time: activityTime,
                    color: "#E0C48A",
                    placeName: nil,
                    notes: generatedActivity.description
                )

                if let firstLink = generatedActivity.links.first {
                    activity.mapLink = firstLink.url
                }

                activity.day = day
                swiftDataActivities.append(activity)
            }

            day.activities = swiftDataActivities
            day.trip       = trip
            swiftDataDays.append(day)
        }

        trip.days = swiftDataDays
        modelContext.insert(trip)

        do {
            try modelContext.save()
            print("✅ Saved: \(trip.name)")
            return trip
        } catch {
            print("❌ Save failed: \(error)")
            return nil
        }
    }

    // MARK: - Time parser "9:00 AM" → (hour, minute)
    private func parseTime(_ timeString: String) -> (hour: Int, minute: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        if let date = formatter.date(from: timeString) {
            let c = Calendar.current.dateComponents([.hour, .minute], from: date)
            return (hour: c.hour ?? 9, minute: c.minute ?? 0)
        }
        return (hour: 9, minute: 0)
    }
}
