import SwiftUI
import Combine

struct AI_Questionnaire_View: View {
    @StateObject private var viewModel = AI_Questionnaire_Model()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color(.background)
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 40) {
                // Progress Bar at top
                ProgressBar(currentStep: viewModel.currentQuestion, totalSteps: 6)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                
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
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                }
                
                // Navigation Buttons at bottom
                NavigationButtons(viewModel: viewModel)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentQuestion)
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
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.45, green: 0.6, blue: 0.5))
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
                    // Generate plan with GPT
                    let prompt = viewModel.generateGPTPrompt()
                    print("GPT Prompt: \(prompt)")
                    // TODO: Call GPT API here
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
        VStack(alignment: .leading, spacing: 8) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Select the City")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Choose your destination in Saudi Arabia")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Cities
            VStack(spacing: 12) {
                ForEach(viewModel.cities) { city in
                    CityButton(
                        city: city,
                        isSelected: viewModel.selectedCity?.id == city.id
                    ) {
                        viewModel.selectedCity = city
                    }
                }
            }
        }
    }
}

struct CityButton: View {
    let city: City
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(city.name)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : Color(red: 0.3, green: 0.25, blue: 0.23))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    isSelected ?
                    Color(red: 0.3, green: 0.25, blue: 0.23) :
                    Color(red: 0.95, green: 0.93, blue: 0.91)
                )
                .cornerRadius(16)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Question 2: Experience Types
struct Question2_ExperienceTypes: View {
    @ObservedObject var viewModel: AI_Questionnaire_Model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("What type of experiences interest you?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Select all that apply")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Experiences Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(viewModel.experiences) { experience in
                    ExperienceButton(
                        experience: experience,
                        isSelected: viewModel.selectedExperiences.contains(experience)
                    ) {
                        if viewModel.selectedExperiences.contains(experience) {
                            viewModel.selectedExperiences.remove(experience)
                        } else {
                            viewModel.selectedExperiences.insert(experience)
                        }
                    }
                }
            }
        }
    }
}

struct ExperienceButton: View {
    let experience: ExperienceType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(experience.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : Color(red: 0.3, green: 0.25, blue: 0.23))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(experience.description)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color(red: 0.3, green: 0.25, blue: 0.23).opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .frame(height: 90)
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

// MARK: - Question 3: Travel Companions
struct Question3_TravelCompanions: View {
    @ObservedObject var viewModel: AI_Questionnaire_Model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Who are you traveling with?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("This helps us personalize your trip!")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Companions
            VStack(spacing: 12) {
                ForEach(viewModel.companions) { companion in
                    CompanionButton(
                        companion: companion,
                        isSelected: viewModel.selectedCompanion?.id == companion.id
                    ) {
                        viewModel.selectedCompanion = companion
                    }
                }
            }
        }
    }
}

struct CompanionButton: View {
    let companion: TravelCompanion
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(companion.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : Color(red: 0.3, green: 0.25, blue: 0.23))
                
                Text(companion.description)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color(red: 0.3, green: 0.25, blue: 0.23).opacity(0.7))
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

// MARK: - Question 4: Budget
struct Question4_Budget: View {
    @ObservedObject var viewModel: AI_Questionnaire_Model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your daily budget per person?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Budget Options
            VStack(spacing: 12) {
                ForEach(viewModel.budgets) { budget in
                    BudgetButton(
                        budget: budget,
                        isSelected: viewModel.selectedBudget?.id == budget.id
                    ) {
                        viewModel.selectedBudget = budget
                    }
                }
            }
        }
    }
}

struct BudgetButton: View {
    let budget: BudgetOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(budget.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : Color(red: 0.3, green: 0.25, blue: 0.23))
                
                Text(budget.range)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color(red: 0.3, green: 0.25, blue: 0.23).opacity(0.7))
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
