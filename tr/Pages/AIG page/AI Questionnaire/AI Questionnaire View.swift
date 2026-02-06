import SwiftUI
import Combine

struct AI_Questionnaire_View: View {
    @StateObject private var viewModel = AI_Questionnaire_Model()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color("Background")
                .ignoresSafeArea()
            
            if viewModel.isGenerating {
                // Loading Screen
                LoadingScreen(viewModel: viewModel)
                    .transition(.opacity)
            } else {
                // Questionnaire Content
                VStack(spacing: 0) {
                    // Progress Bar at top
                    ProgressBar(currentStep: viewModel.currentQuestion, totalSteps: 6)
                        .padding(.horizontal, 30)
                        .padding(.top, 16)
                    
                    // Question Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            switch viewModel.currentQuestion {
                            case 1:
                                Question1_CitySelection(viewModel: viewModel)
                            case 2:
                                Question2_ExperienceTypes(viewModel: viewModel)
                            case 3:
                                Question3_TravelCompanions(viewModel: viewModel)
                            case 4:
                                Question4_Budget(viewModel: viewModel)
                            case 5:
                                Question5_Days(viewModel: viewModel)
                            case 6:
                                Question6_TravelPace(viewModel: viewModel)
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    }
                    
                    // Navigation Buttons at bottom
                    NavigationButtons(viewModel: viewModel)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 40)
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentQuestion)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isGenerating)
    }
}

// MARK: - Loading Screen
struct LoadingScreen: View {
    @ObservedObject var viewModel: AI_Questionnaire_Model
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                // Title and subtitle
                VStack(spacing: 12) {
                    Text("Creating your journey")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.23))
                    
                    Text("Our AI is crafting the perfect itinerary\nbased on your preferences")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.43))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 40)
                
                // Circular Progress
                ZStack {
                    // Background Circle
                    Circle()
                        .stroke(Color(red: 0.85, green: 0.82, blue: 0.8), lineWidth: 12)
                        .frame(width: 280, height: 280)
                    
                    // Progress Circle
                    Circle()
                        .trim(from: 0, to: viewModel.generationProgress)
                        .stroke(
                            Color(red: 0.45, green: 0.6, blue: 0.5),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: viewModel.generationProgress)
                    
                    // Center Content
                    VStack(spacing: 16) {
                        Text("\(Int(viewModel.generationProgress * 100))%")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.45, green: 0.6, blue: 0.5))
                        
                        Text(viewModel.generationStep)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.23))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .padding(.top, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.96, green: 0.94, blue: 0.92))
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("Light small text").opacity(0.35))
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("Green"))
                    .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 4)
                    .animation(.spring(response: 0.5), value: currentStep)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Navigation Buttons
struct NavigationButtons: View {
    @ObservedObject var viewModel: AI_Questionnaire_Model
    
    var body: some View {
        HStack(spacing: 12) {
            // Back Button
            Button(action: {
                viewModel.goToPreviousQuestion()
            }) {
                Text("Back")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.23))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(red: 0.85, green: 0.82, blue: 0.8))
                    .cornerRadius(25)
            }
            .disabled(viewModel.currentQuestion == 1)
            .opacity(viewModel.currentQuestion == 1 ? 0.5 : 1)
            
            // Next Button
            Button(action: {
                if viewModel.currentQuestion == 6 {
                    // Start generation with loading screen
                    viewModel.startGeneration()
                } else {
                    viewModel.goToNextQuestion()
                }
            }) {
                Text(viewModel.currentQuestion == 6 ? "Generate Plan" : "Next")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        viewModel.isCurrentQuestionValid() ?
                        Color(red: 0.3, green: 0.25, blue: 0.23) :
                        Color(red: 0.85, green: 0.82, blue: 0.8)
                    )
                    .cornerRadius(25)
            }
            .disabled(!viewModel.isCurrentQuestionValid())
            .animation(.easeInOut(duration: 0.2), value: viewModel.isCurrentQuestionValid())
        }
    }
}

// MARK: - Question 1: City Selection

struct Question1_CitySelection: View {
    @ObservedObject var viewModel: AI_Questionnaire_Model
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Title (MATCHES Question 2)
            VStack(spacing: 10) {
                Text("Select the City")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(Color("Title"))
                    .multilineTextAlignment(.center)

                Text("Choose your destination in Saudi Arabia")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(Color("Light small text"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            
            // City buttons
            // City buttons (CENTERED column)
            VStack(spacing: 18) {
                ForEach(viewModel.cities) { city in
                    CityButton(
                        title: city.name,
                        isSelected: viewModel.selectedCity?.id == city.id
                    ) {
                        viewModel.selectedCity = city
                    }
                }
            }
            .frame(maxWidth: 340)          // ✅ controls the “column” width like the design
            .frame(maxWidth: .infinity)    // ✅ centers that column in the screen
        }
    }
}

struct CityButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack  {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : Color("Title"))
                    .padding(.top, 2)
                   

                Spacer()
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(
                isSelected ? Color("Button click") : Color.white
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            
            .shadow(
                color: Color.black.opacity(0.06),
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Question 2: Experience Types
struct Question2_ExperienceTypes: View {
    @ObservedObject var viewModel: AI_Questionnaire_Model
    
    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]
    private func toggleExperience(_ experience: ExperienceType) {
        if viewModel.selectedExperiences.contains(experience) {
            viewModel.selectedExperiences.remove(experience)
        } else {
            viewModel.selectedExperiences.insert(experience)
        }
    }
    var body: some View {
        
        VStack(spacing: 22) {
            
            // Title (CENTERED like the design)
            VStack(spacing: 10) {
                Text("What type of experiences\ninterest you?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("Title"))
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(Color("Light small text").opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            
            VStack(spacing: 18) {
                
                // first 4 items (2x2)
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(Array(viewModel.experiences.prefix(4))) { experience in
                        ExperienceCard(
                            title: experience.title.replacingOccurrences(of: "\n", with: " "),
                            description: experience.description,
                            isSelected: viewModel.selectedExperiences.contains(experience)
                        ) {
                            toggleExperience(experience)
                        }
                    }
                }
                
                // last item centered
                if let last = viewModel.experiences.last {
                    HStack {
                        Spacer()
                        ExperienceCard(
                            title: last.title.replacingOccurrences(of: "\n", with: " "),
                            description: last.description,
                            isSelected: viewModel.selectedExperiences.contains(last)
                        ) {
                            toggleExperience(last)
                        }
                        .frame(maxWidth: 210) // tweak if you want wider/narrower
                        Spacer()
                    }
                }
            }
        }
    }
    struct ExperienceCard: View {
        let title: String
        let description: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 10) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : Color("Title"))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                    
                    Text(description)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(
                            isSelected
                            ? .white.opacity(0.85)
                            : Color("Light small text").opacity(0.6)
                        )
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .frame(height: 135)
                .background(isSelected ? Color("Button click") : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.black.opacity(0.04), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.18), value: isSelected)
        }
    }
}
// MARK: - Question 3: Travel Companions (MATCHING SKETCH – SMALLER)

struct Question3_TravelCompanions: View {
    @ObservedObject var viewModel: AI_Questionnaire_Model

    var body: some View {
        VStack(spacing: 18) {

            // Title
            VStack(spacing: 8) {
                Text("Who are you traveling\nwith?")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(Color("Title"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text("This helps us personalize your trip!")
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(Color("Green"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            // Cards
            VStack(spacing: 14) {
                ForEach(viewModel.companions) { companion in
                    CompanionCard(
                        companion: companion,
                        isSelected: viewModel.selectedCompanion?.id == companion.id
                    ) {
                        viewModel.selectedCompanion = companion
                    }
                }
            }
            .frame(maxWidth: 320)
            .frame(maxWidth: .infinity)
        }
    }
}

struct CompanionCard: View {
    let companion: TravelCompanion
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(companion.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : Color("Title"))

                Text(companion.description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(
                        isSelected
                        ? .white.opacity(0.85)
                        : Color("Light small text")
                    )
                    .lineLimit(2)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 100)
            .background(isSelected ? Color("Button click") : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}

// MARK: - Question 4: Budget
// MARK: - Question 4: Budget
struct Question4_Budget: View {
    @ObservedObject var viewModel: AI_Questionnaire_Model

    var body: some View {
        VStack(spacing: 0) {

            // Title
            VStack(spacing: 8) {
                Text("What's your daily budget per person?")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(Color("Title"))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)

            // ⬇️ space between title and cards
            Spacer()
                .frame(height: 28)

            // Budget cards
            VStack(spacing: 16) {
                ForEach(viewModel.budgets) { budget in
                    BudgetButton(
                        budget: budget,
                        isSelected: viewModel.selectedBudget?.id == budget.id
                    ) {
                        viewModel.selectedBudget = budget
                    }
                }
            }
            .frame(maxWidth: 360)   // same width feel as Question 1
            .frame(maxWidth: .infinity)

            Spacer()
        }
    }
}

struct BudgetButton: View {
    let budget: BudgetOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(budget.title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? .white : Color("Title"))

                    Text(budget.range)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(
                            isSelected
                            ? .white.opacity(0.85)
                            : Color.gray.opacity(0.7)
                        )
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(height: 86) // ⬅️ elongated like Question 1
            .background(
                isSelected
                ? Color("Button click")
                : Color.white
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

    // MARK: - Question 5: Days
    struct Question5_Days: View {
        @ObservedObject var viewModel: AI_Questionnaire_Model
        
        var body: some View {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("How many days will you be traveling?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Maximum 7 days")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Day Display
                VStack(spacing: 32) {
                    // Large Day Number
                    Text("\(Int(viewModel.numberOfDays))")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Day")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .offset(y: -20)
                    
                    // Slider
                    VStack(spacing: 8) {
                        Slider(value: $viewModel.numberOfDays, in: 1...viewModel.maxDays, step: 1)
                            .accentColor(Color(red: 0.3, green: 0.25, blue: 0.23))
                        
                        HStack {
                            Text("1 Day")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Spacer()
                            
                            Text("7 Day")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    // Quick Select Buttons
                    HStack(spacing: 12) {
                        QuickDayButton(day: 2, label: "WEEKEND", viewModel: viewModel)
                        QuickDayButton(day: 3, label: "SHORT", viewModel: viewModel)
                        QuickDayButton(day: 5, label: "WEEK", viewModel: viewModel)
                    }
                    
                    // Perfect For Label
                    VStack(spacing: 8) {
                        Text("PERFECT FOR")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.45, green: 0.6, blue: 0.5))
                            .cornerRadius(12)
                        
                        Text("Quick stopover to see the main attractions")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
    
    struct QuickDayButton: View {
        let day: Int
        let label: String
        @ObservedObject var viewModel: AI_Questionnaire_Model
        
        var body: some View {
            VStack(spacing: 4) {
                Text("\(day)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .onTapGesture {
                viewModel.numberOfDays = Double(day)
            }
        }
    }
    
    // MARK: - Question 6: Travel Pace
    struct Question6_TravelPace: View {
        @ObservedObject var viewModel: AI_Questionnaire_Model
        
        var body: some View {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("How do you prefer to travel?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Choose your ideal pace")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Pace Options
                VStack(spacing: 16) {
                    ForEach(viewModel.paces) { pace in
                        PaceButton(
                            pace: pace,
                            isSelected: viewModel.selectedPace?.id == pace.id
                        ) {
                            viewModel.selectedPace = pace
                        }
                    }
                }
            }
        }
    }
    
    struct PaceButton: View {
        let pace: TravelPace
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(pace.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : Color(red: 0.3, green: 0.25, blue: 0.23))
                    
                    Text(pace.description)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(red: 0.3, green: 0.25, blue: 0.23).opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Tags
                    HStack(spacing: 8) {
                        ForEach(pace.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(isSelected ? .white : Color(red: 0.3, green: 0.25, blue: 0.23))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(isSelected ? Color.white.opacity(0.2) : Color(red: 0.85, green: 0.82, blue: 0.8))
                                .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    isSelected ?
                    Color(red: 0.3, green: 0.25, blue: 0.23) :
                        Color(red: 0.95, green: 0.93, blue: 0.91)
                )
                .cornerRadius(12)
            }
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
    
    // MARK: - Preview
    struct AI_Questionnaire_View_Previews: PreviewProvider {
        static var previews: some View {
            AI_Questionnaire_View()
        }
    }

