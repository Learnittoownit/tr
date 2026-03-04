import Foundation
import SwiftUI
import Combine
import SwiftData
import Security

// MARK: - Questionnaire Data Models

struct CityFamiliarity: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
}

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
    let kidsStatus: KidsStatus

    enum KidsStatus {
        case notAllowed   // [KIDS_NOT_ALLOWED]
        case welcome      // [KIDS_WELCOME]
    }
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

    // Current question index (1-7)
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

    // MARK: - PROTECTED Counter with iCloud Keychain
    private let keychainGenerationsKey = "ai_remaining_v6"
    private let keychainMonthYearKey = "ai_month_year_v3"
    private let keychainInitializedKey = "ai_initialized_v3"
    private let maxGenerationsPerMonth = 5

    @Published var remainingGenerations: Int = 5 {
        didSet {
            saveToKeychain(key: keychainGenerationsKey, value: remainingGenerations)
            print("💾 Saved to Keychain: \(remainingGenerations)")
        }
    }

    // MARK: - Load or Reset Generations
    private func loadOrResetGenerations() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        let currentMonthYear = "\(currentYear)-\(currentMonth)"
        
        let savedMonthYear = loadFromKeychain(key: keychainMonthYearKey) as? String ?? ""
        let isInitialized = (loadFromKeychain(key: keychainInitializedKey) as? Bool) ?? false
        
        if !isInitialized {
            print("🆕 First launch — initializing to \(maxGenerationsPerMonth)")
            _remainingGenerations = Published(initialValue: maxGenerationsPerMonth)
            saveToKeychain(key: keychainGenerationsKey, value: maxGenerationsPerMonth)
            saveToKeychain(key: keychainMonthYearKey, value: currentMonthYear)
            saveToKeychain(key: keychainInitializedKey, value: true)
            
        } else if savedMonthYear != currentMonthYear {
            print("🔄 New month — resetting to \(maxGenerationsPerMonth)")
            _remainingGenerations = Published(initialValue: maxGenerationsPerMonth)
            saveToKeychain(key: keychainGenerationsKey, value: maxGenerationsPerMonth)
            saveToKeychain(key: keychainMonthYearKey, value: currentMonthYear)
            
        } else {
            let saved = (loadFromKeychain(key: keychainGenerationsKey) as? Int) ?? maxGenerationsPerMonth
            print("📦 Same month — loaded: \(saved)")
            _remainingGenerations = Published(initialValue: saved)
        }
    }

    // MARK: - Keychain Helpers
    private func saveToKeychain(key: String, value: Any) {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false) else {
            print("❌ Failed to archive \(key)")
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: true
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        print(status == errSecSuccess ? "✅ Keychain saved: \(key)" : "❌ Keychain save failed: \(status)")
    }

    private func loadFromKeychain(key: String) -> Any? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecAttrSynchronizable as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        
        return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
    }

    // MARK: - Q1: City Familiarity
    @Published var selectedFamiliarity: CityFamiliarity?
    let familiarityOptions = [
        CityFamiliarity(title: "I'm a local here",    description: ""),
        CityFamiliarity(title: "I've visited before", description: ""),
        CityFamiliarity(title: "It's my first visit", description: "")
    ]

    // MARK: - Q2: City (was Q1)
    @Published var selectedCity: City?
    let cities = [
        City(name: "Riyadh"),
        City(name: "Jeddah"),
        City(name: "Abha")
    ]

    // MARK: - Q3: Experience Types (was Q2)
    @Published var selectedExperiences: Set<ExperienceType> = []
    let experiences = [
        ExperienceType(title: "Cultural &\nHistorical", description: "Museums, heritage sites, and monuments"),
        ExperienceType(title: "Adventure &\nNature",    description: "Hiking, deserts, and natural landscapes"),
        ExperienceType(title: "Relaxation",             description: "Serenity, tranquility, and wellness"),
        ExperienceType(title: "Shopping &\nModern",     description: "Malls, boutiques, urban attractions"),
        ExperienceType(title: "Food &\nDining",         description: "Restaurants, fine dining, and local cuisine"),
        ExperienceType(title: "Cafés &\nCoffee",        description: "Coffee shops, dessert cafés, and specialty drinks")
    ]

    // MARK: - Q4: Travel Companions
    @Published var selectedCompanion: TravelCompanion?
    let companions = [
        TravelCompanion(title: "Solo",                 description: "Independent exploration at your own pace"),
        TravelCompanion(title: "Couple",               description: "Romantic experiences and intimate settings"),
        TravelCompanion(title: "Friends Group",        description: "Social activities and group adventures"),
        TravelCompanion(title: "Family with Children", description: "Kid-friendly activities and family attractions"),
    ]

    // MARK: - Q5: Budget
    @Published var selectedBudget: BudgetOption?
    let budgets = [
        BudgetOption(title: "Budget-Friendly", range: "300-600 SAR/day"),
        BudgetOption(title: "Mid-Range",       range: "600-1200 SAR/day"),
        BudgetOption(title: "Luxury",          range: "1,200+ SAR/day")
    ]

    // MARK: - Q6: Number of Days
    @Published var numberOfDays: Double = 1
    let maxDays: Double = 7

    var selectedDays: Int {
        get { Int(numberOfDays.rounded()) }
        set { numberOfDays = Double(newValue) }
    }

    // MARK: - Q7: Travel Pace
    @Published var selectedPace: TravelPace?
    let paces = [
        TravelPace(
            title: "Relaxed",
            description: "Take it slow and enjoy plenty of downtime between activities. Perfect for soaking in the atmosphere.",
            tags: ["2-3 activities", "Lots of free time", "Flexible schedule"]
        ),
        TravelPace(
            title: "Moderate",
            description: "Balanced approach with structured planning time to rest. The sweet spot for most travelers.",
            tags: ["4-5 activities", "Balanced schedule", "Some flexibility"]
        ),
        TravelPace(
            title: "Packed",
            description: "Maximize every moment with back-to-back experiences. See and do as much as possible in limited time.",
            tags: ["6+ activities", "Full days", "Efficient routing"]
        )
    ]

    // MARK: - Init
    init() {
        loadOrResetGenerations()
    }

    // MARK: - Navigation
    func goToNextQuestion() {
        if currentQuestion < 7 {
            currentQuestion += 1
        }
    }

    func goToPreviousQuestion() {
        if currentQuestion > 1 {
            currentQuestion -= 1
        }
    }

    // MARK: - Validation
    func isCurrentQuestionValid() -> Bool {
        switch currentQuestion {
        case 1: return selectedCity != nil
        case 2: return selectedFamiliarity != nil
        case 3: return !selectedExperiences.isEmpty
        case 4: return selectedCompanion != nil
        case 5: return selectedBudget != nil
        case 6: return true
        case 7: return selectedPace != nil
        default: return false
        }
    }

    // MARK: - Build GPT prompt
    func generateGPTPrompt() -> String {
        var parts: [String] = []

        if let city = selectedCity {
            parts.append("Destination: \(city.name), Saudi Arabia")
        }
        if let familiarity = selectedFamiliarity {
            let instruction: String
            switch familiarity.title {
            case "I'm a local here":
                instruction = "This traveler knows the city very well. Prioritize hidden gems, local favorites, and off-the-beaten-path spots. Avoid obvious tourist traps and well-known landmarks they've surely seen."
            case "I've visited before":
                instruction = "This traveler has visited a few times. Mix some beloved classics they may have missed with newer, lesser-known spots locals enjoy."
            default:
                instruction = "This traveler is visiting for the first time. Include iconic must-see landmarks, top-rated attractions, and the most celebrated local experiences."
            }
            parts.append("City familiarity: \(familiarity.title) — \(instruction)")
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
        guard remainingGenerations > 0 else {
            print("🚫 No generations remaining this month")
            return
        }

        isGenerating = true
        generationFailed = false
        generationProgress = 0.0
        generationStep = "Analyzing your preferences..."

        Task {
            do {
                await animateTo(progress: 0.15, step: "Analyzing your preferences...", duration: 0.6)

                let prompt      = generateGPTPrompt()
                let familiarity = selectedFamiliarity?.title ?? "It's my first visit"
                let city        = selectedCity?.name ?? ""
                let interests   = selectedExperiences.map { $0.title }
                let budget      = selectedBudget?.title ?? "Mid-Range"
                let companions  = selectedCompanion?.title ?? ""
                let service     = OpenAIService()
                let totalDays   = Int(numberOfDays)

                // ── Pass 1: Generate the plan ─────────────────────────────
                // Day 1 starts — API call is the real work happening here
                await animateTo(progress: 0.20, step: "Building Day 1 of \(totalDays)...", duration: 0.5)

                let rawPlan = try await service.generatePlan(
                    prompt: prompt,
                    familiarity: familiarity,
                    city: city,
                    interests: interests,
                    budget: budget,
                    companions: companions
                )

                print("Pass 1 complete")

                // ── API returned — mark Day 1 done, advance remaining days ─
                // Each day gets a real 1.5s pause so it feels like genuine work
                await animateTo(progress: 0.30, step: "Building Day 1 of \(totalDays)...", duration: 0.4)

                if totalDays > 1 {
                    let progressPerDay = 0.35 / Double(totalDays - 1)
                    for day in 2...totalDays {
                        let target = 0.30 + progressPerDay * Double(day - 1)
                        await animateTo(progress: target - progressPerDay * 0.5,
                                        step: "Building Day \(day) of \(totalDays)...", duration: 0.5)
                        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s real pause per day
                        await animateTo(progress: target,
                                        step: "Building Day \(day) of \(totalDays)...", duration: 0.4)
                    }
                }

                // ── Pass 2: Geo-filter — cluster each day by zone ─────────
                await animateTo(progress: 0.70, step: "Optimizing locations for you...", duration: 0.6)

                let filteredPlan = try await service.geoFilterPass(
                    rawJSON: rawPlan,
                    city: city,
                    budget: budget
                )

                print("Pass 2 complete")

                // ── Parse final result ────────────────────────────────────
                await animateTo(progress: 0.90, step: "Putting the finishing touches...", duration: 0.5)

                let trip = try service.parseGeneratedTrip(from: filteredPlan)

                await animateTo(progress: 1.0, step: "Your plan is ready!", duration: 0.4)
                try? await Task.sleep(nanoseconds: 500_000_000)

                await MainActor.run {
                    // ✅ Only deduct AFTER successful generation
                    self.remainingGenerations -= 1
                    print("🔢 Generation used. Remaining: \(self.remainingGenerations)")

                    self.generatedTrip     = trip
                    self.isGenerating      = false
                    self.showGeneratedPlan = true
                }

            } catch {
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("❌ GENERATION FAILED — limit NOT deducted")
                print("❌ Error: \(error)")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

                await MainActor.run {
                    self.isGenerating           = false
                    self.generationFailed       = true
                    self.generationErrorMessage = error.localizedDescription
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

        selectedFamiliarity = nil
        selectedCity        = nil
        selectedExperiences.removeAll()
        selectedCompanion   = nil
        selectedBudget      = nil
        numberOfDays        = 1
        selectedPace        = nil
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
