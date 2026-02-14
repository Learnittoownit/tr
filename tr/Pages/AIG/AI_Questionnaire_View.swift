import SwiftUI
import Combine

    struct AI_Questionnaire_View: View {
        @ObservedObject var viewModel: AI_Questionnaire_Model
        @Binding var showPrePage: Bool
        @State private var navigateToJournal = false
        var goToMain: (() -> Void)? = nil
    
    // ─────────────────────────────────────────────────────────────
    // In AI_Questionnaire_View.swift, find the body var and
    // ADD this one extra condition before the "else" at the bottom.
    // Replace the entire body var with the version below:
    // ─────────────────────────────────────────────────────────────
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            if viewModel.showGeneratedPlan {
                NavigationStack {
                    AI_Plan_View(
                        viewModel: viewModel,
                        showPrePage: $showPrePage,
                        onSaveToJournal: {
                            navigateToJournal = true
                        },
                        goToMain: goToMain)                }
                .transition(.opacity)
            } else if viewModel.isGenerating {
                LoadingScreen(viewModel: viewModel)
                    .transition(.opacity)
                
            } else if viewModel.generationFailed {
                // ── Error state: shown if the API call fails ──────────────
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundColor(Color("Green").opacity(0.7))
                    
                    VStack(spacing: 10) {
                        Text("Something went wrong")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color("Title"))
                        
                        Text("Couldn't connect to the AI. Please check your internet connection and try again.")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(Color("Light small text"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    Button {
                        viewModel.generationFailed = false
                        viewModel.generationProgress = 0.0
                        // Go back to question 6 so user can retry
                        viewModel.currentQuestion = 6
                    } label: {
                        Text("Try Again")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("Background"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color("Next button"))
                            .cornerRadius(27)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
                .transition(.opacity)
                
            } else {
                // ── Normal questionnaire flow ─────────────────────────────
                VStack(spacing: 0) {
                    ProgressBar(currentStep: viewModel.currentQuestion, totalSteps: 6)
                        .padding(.horizontal, 30)
                        .padding(.top, 16)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            switch viewModel.currentQuestion {
                            case 1: Question1_CitySelection(viewModel: viewModel)
                            case 2: Question2_ExperienceTypes(viewModel: viewModel)
                            case 3: Question3_TravelCompanions(viewModel: viewModel)
                            case 4: Question4_Budget(viewModel: viewModel)
                            case 5: Question5_Days(viewModel: viewModel)
                            case 6: Question6_TravelPace(viewModel: viewModel)
                            default: EmptyView()
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                    }
                    
                    NavigationButtons(viewModel: viewModel)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 10)
                }
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentQuestion)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isGenerating)
        .animation(.easeInOut(duration: 0.3), value: viewModel.generationFailed)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.showGeneratedPlan)
        .navigationDestination(isPresented: $navigateToJournal) {
            JournalView()
        }
    }
    
    
    // MARK: - Loading Screen
    struct LoadingScreen: View {
        @ObservedObject var viewModel: AI_Questionnaire_Model
        
        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Text("Creating your journey")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color("title loading page"))
                        Text("Our AI is crafting the perfect itinerary\nbased on your preferences!").bold()
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(Color("small text loading page")).bold()
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 40)
                    
                    ZStack {
                        Circle()
                            .stroke(Color(red: 0.85, green: 0.82, blue: 0.8), lineWidth: 12)
                            .frame(width: 280, height: 280)
                        
                        Circle()
                            .trim(from: 0, to: viewModel.generationProgress)
                            .stroke(
                                Color(red: 0.45, green: 0.6, blue: 0.5),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 280, height: 280)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: viewModel.generationProgress)
                        
                        VStack(spacing: 16) {
                            Text("\(Int(viewModel.generationProgress * 100))%")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.45, green: 0.6, blue: 0.5))
                            
                            Text(viewModel.generationStep)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(Color("small text loading page"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    .padding(.top, 40)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("Background"))
        }
    }
    
    // MARK: - Progress Bar
    struct ProgressBar: View {
        let currentStep: Int
        let totalSteps: Int
        
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("PB"))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color("Green"))
                        .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 6)
                        .animation(.spring(response: 0.5), value: currentStep)
                }
            }
            .frame(height: 4)
        }
    }

    
    struct NavigationButtons: View {
        @ObservedObject var viewModel: AI_Questionnaire_Model
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            HStack(spacing: 12) {
                
                // ✅ Only show Back button if NOT question 1
                if viewModel.currentQuestion != 1 {
                    Button {
                        viewModel.goToPreviousQuestion()
                    } label: {
                        Text("Back")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("W"))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color("Back button"))
                            .cornerRadius(25)
                    }
                }
                
                // Next / Generate
                Button {
                    viewModel.currentQuestion == 6
                    ? viewModel.startGeneration()
                    : viewModel.goToNextQuestion()
                } label: {
                    Text(viewModel.currentQuestion == 6 ? "Generate Plan" : "Next")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(nextButtonTextColor)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(nextButtonBackgroundColor)
                        .cornerRadius(25)
                }
                .disabled(!viewModel.isCurrentQuestionValid())
                .opacity(nextButtonOpacity)
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.currentQuestion)
        }
        
        // ✅ NEXT BUTTON COLOR LOGIC
        private var nextButtonTextColor: Color {
            let isValid = viewModel.isCurrentQuestionValid()
            
            if colorScheme == .light {
                return isValid ? Color("Background") : Color("Title").opacity(0.4)
            } else {
                return isValid ? Color("Background") : Color("Title")
            }
        }
        
        private var nextButtonBackgroundColor: Color {
            let isValid = viewModel.isCurrentQuestionValid()
            
            if colorScheme == .light {
                return isValid ? Color("Next button") : Color("Back button")
            } else {
                return isValid ? Color("Next button") : Color("Back button")
            }
        }
        
        private var nextButtonOpacity: Double {
            let isValid = viewModel.isCurrentQuestionValid()
            
            if colorScheme == .light {
                return isValid ? 1.0 : 0.5
            } else {
                return 1.0
            }
        }
    }
    
    // MARK: - Question 1: City Selection
    struct Question1_CitySelection: View {
        @ObservedObject var viewModel: AI_Questionnaire_Model
        
        var body: some View {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Text("Select the City")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color("Title"))
                        .multilineTextAlignment(.center)
                    
                    Text("Choose your destination in Saudi Arabia\n\n").bold()
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundColor(Color("Light small text"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 21) {
                    ForEach(viewModel.cities) { city in
                        CityButton(
                            title: city.name,
                            isSelected: viewModel.selectedCity?.id == city.id
                        ) {
                            viewModel.selectedCity = city
                        }
                    }
                }
                .frame(maxWidth: 340)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    struct CityButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(
                            isSelected ? Color("Background") : Color("Options")
                        )
                    Spacer()
                }
                .padding(.horizontal, 28)
                .frame(height: 96)
                .background(isSelected ? Color("Button click") : Color("Card"))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
    
        struct Question2_ExperienceTypes: View {
            @ObservedObject var viewModel: AI_Questionnaire_Model
            
            private let gridSpacing: CGFloat = 20
            private let sidePadding: CGFloat = 1
            private let cardHeight: CGFloat = 165
            
            private func toggle(_ experience: ExperienceType) {
                if viewModel.selectedExperiences.contains(experience) {
                    viewModel.selectedExperiences.remove(experience)
                } else {
                    viewModel.selectedExperiences.insert(experience)
                }
            }
            
            var body: some View {
                GeometryReader { geo in
                    let gridWidth = geo.size.width - (sidePadding * 2)
                    let cardWidth = (gridWidth - gridSpacing) / 2
                    
                    VStack(spacing: 18) {
                        
                        VStack(spacing: 8) {
                            Text("What type of experiences\ninterest you?")
                                .font(.system(size: 27, weight: .bold, design: .rounded))
                                .foregroundColor(Color("Title"))
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Select all that apply").bold()
                                .font(.system(size: 20))
                                .foregroundColor(Color("Light small text"))
                        }
                        .frame(maxWidth: .infinity)
                        
                        // 2x3 Grid for all 6 items
                        LazyVGrid(
                            columns: [
                                GridItem(.fixed(cardWidth), spacing: gridSpacing),
                                GridItem(.fixed(cardWidth), spacing: gridSpacing)
                            ],
                            spacing: 16
                        ) {
                            ForEach(viewModel.experiences) { experience in
                                ExperienceCard(
                                    title: experience.title,
                                    description: experience.description,
                                    isSelected: viewModel.selectedExperiences.contains(experience)
                                ) {
                                    toggle(experience)
                                }
                                .frame(width: cardWidth, height: cardHeight)
                            }
                        }
                        .frame(width: gridWidth)
                        
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, sidePadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? Color("select") : Color("Options"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(isSelected ? Color("Select dis") : Color("Light small text"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(isSelected ? Color("Button click") : Color("Card"))
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 4)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
    
    // MARK: - Question 3: Travel Companions
    struct Question3_TravelCompanions: View {
        @ObservedObject var viewModel: AI_Questionnaire_Model
        
        var body: some View {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text("Who are you traveling\nwith?")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color("Title"))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    Text("This helps us personalize your trip!\n").bold()
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .foregroundColor(Color("Light small text"))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                
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
                VStack(alignment: .leading, spacing: 6) {
                    
                    Text(companion.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(
                            isSelected ? Color("select") : Color("Options")
                        )
                    
                    Text(companion.description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(
                            isSelected
                            ? Color("Select dis")
                            : Color("Light small text")
                        )
                        .lineLimit(2)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 100)
                .background(
                    isSelected ? Color("Button click") : Color("Card")
                )
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.black.opacity(0.04), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 8, y: 5)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
    
    // MARK: - Question 4: Budget
    struct Question4_Budget: View {
        @ObservedObject var viewModel: AI_Questionnaire_Model
        
        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 8) {
                    Text("What's your daily budget per person?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color("Title"))
                        .multilineTextAlignment(.center)
                }
                
                Spacer().frame(height: 50)
                
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
                .frame(maxWidth: 360)
                .frame(maxWidth: .infinity)
                
                Spacer()
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
                            .foregroundColor(
                                isSelected ? Color("select") : Color("Options")
                            )
                        
                        Text(budget.range)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(
                                isSelected
                                ? Color("Select dis")
                                : Color("Light small text")
                            )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(height: 112)
                .background(
                    isSelected ? Color("Button click") : Color("Card")
                )
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 8)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
    
    // MARK: - Question 5: Days
    struct Question5_Days: View {
        @ObservedObject var viewModel: AI_Questionnaire_Model
        @Environment(\.colorScheme) var colorScheme
        
        private let titleColor = Color(red: 0.30, green: 0.25, blue: 0.23)
        
        var body: some View {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("How many days will you be traveling?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(
                            colorScheme == .dark
                            ? Color("Title")
                            : titleColor
                        )
                        .multilineTextAlignment(.center)
                    
                    Text("Maximum 7 days\n\n").bold()
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .foregroundColor(
                            colorScheme == .dark
                            ? Color("Light small text")
                            : Color("Light small text")
                        )
                }
                .padding(.top, 10)
                
                Spacer()
                
                VStack(spacing: 0) {
                    Text("\(Int(viewModel.numberOfDays))")
                        .font(.custom("Impact", size: 60))
                        .foregroundColor(Color("Green"))
                    
                    Text("Day")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(
                            colorScheme == .dark
                            ? Color("Light small text")
                            : Color("Light small text")
                        )
                }
                
                Spacer().frame(height: 30)
                
                VStack(spacing: 12) {
                    Slider(value: $viewModel.numberOfDays, in: 1...7, step: 1)
                        .tint(titleColor)
                    
                    HStack {
                        Text("1 Day")
                        Spacer()
                        Text("7 Day")
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(
                        colorScheme == .dark
                        ? Color("Light small text")
                        : Color("Light small text")
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer().frame(height: 30)
                
                HStack(spacing: 16) {
                    QuickDayCard(number: 2, label: "WEEKEND",
                                 isSelected: Int(viewModel.numberOfDays) == 2) {
                        viewModel.numberOfDays = 2
                    }
                    
                    QuickDayCard(number: 3, label: "SHORT",
                                 isSelected: Int(viewModel.numberOfDays) == 3) {
                        viewModel.numberOfDays = 3
                    }
                    
                    QuickDayCard(number: 5, label: "WEEK",
                                 isSelected: Int(viewModel.numberOfDays) == 5) {
                        viewModel.numberOfDays = 5
                    }
                }
                
                Spacer().frame(height: 20)
                
                QuickDayInfoCard(
                    bg: Color("Green"),
                    text: perfectForText
                )
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        
        private var perfectForText: String {
            let days = Int(viewModel.numberOfDays)
            switch days {
            case 1:
                return "Quick stopover to see the main attraction."
            case 2:
                return "Weekend getaway with essential experiences."
            case 3, 4:
                return "Quick city exploration with major highlights."
            case 5, 6, 7:
                return "Full week to explore at a comfortable pace."
            default:
                return ""
            }
        }
    }
    
    struct QuickDayCard: View {
        let number: Int
        let label: String
        let isSelected: Bool
        let action: () -> Void
        
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 6) {
                    Text("\(number)")
                        .font(.custom("Impact", size: 60))
                        .foregroundColor(isSelected ? Color("Green") : numberColor)
                    
                    Text(label)
                        .font(.system(size: 15, weight: .semibold, design: .rounded)) // <- size changed to 15
                        .foregroundColor(isSelected ? Color("Background") : labelColor)
                }
                .frame(width: 96, height: 96)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(
                    color: Color.black.opacity(colorScheme == .light ? 0.06 : 0.1),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        
        private var backgroundColor: Color {
            if isSelected {
                return colorScheme == .dark
                ? Color("Button click")
                : Color("Button click")
            } else {
                return colorScheme == .dark
                ? Color("Card")
                : Color.white
            }
        }
        
        private var numberColor: Color {
            if colorScheme == .dark {
                return .white
            } else {
                return isSelected
                ? .white
                : Color(red: 0.27, green: 0.22, blue: 0.19)
            }
        }
        
        private var labelColor: Color {
            if colorScheme == .dark {
                return Color("Light small text")
            } else {
                return isSelected
                ? .white.opacity(0.85)
                : Color.gray.opacity(0.7)
            }
        }
    }
    
    struct QuickDayInfoCard: View {
        let bg: Color
        let text: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                
                Text("PERFECT FOR").font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text(text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true).padding(.horizontal, 10)
                    .padding(.vertical, 5)
                
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg)
            .cornerRadius(24)
            .padding(.horizontal, 10)
        }
    }
    
    // MARK: - Question 6: Travel Pace
    struct Question6_TravelPace: View {
        @ObservedObject var viewModel: AI_Questionnaire_Model
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            VStack {
                VStack(spacing: 8) {
                    Text("How do you prefer to travel?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color("Title"))
                        .multilineTextAlignment(.center)
                    
                    Text("Choose your ideal pace").bold()
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .foregroundColor(Color("Light small text"))
                }
                .padding(.top, 10)
                .padding(.horizontal, 30)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        ForEach(viewModel.paces) { pace in
                            PaceButton(
                                pace: pace,
                                isSelected: viewModel.selectedPace?.id == pace.id
                            ) {
                                viewModel.selectedPace = pace
                            }
                        }
                    }
                    .padding(.top, 30)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
            }
            .background(Color("Background").ignoresSafeArea())
        }
    }
    
    struct PaceButton: View {
        let pace: TravelPace
        let isSelected: Bool
        let action: () -> Void
        @Environment(\.colorScheme) var colorScheme
        
        private let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 16) {
                    
                    Text(pace.title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(titleColor)
                    
                    Text(pace.description)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(descriptionColor)
                        .lineSpacing(4)
                    
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(pace.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(tagTextColor)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(tagBackgroundColor)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
                .background(cardBackgroundColor)
                .cornerRadius(32)
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
        }
        
        private var cardBackgroundColor: Color {
            if isSelected {
                return colorScheme == .dark ? Color("Button click") : Color("Button click")
            } else {
                return colorScheme == .dark ? Color("Card") : Color("Card")
            }
        }
        
        private var titleColor: Color {
            if isSelected {
                return colorScheme == .dark ? Color("Card") : Color("Background")
            } else {
                return colorScheme == .dark ? Color("a") : Color("Title")
            }
        }
        
        private var descriptionColor: Color {
            if isSelected {
                return colorScheme == .dark ? Color("Light small text") : Color("Background").opacity(0.8)
            } else {
                return colorScheme == .dark ? Color("Light small text") : Color("Light small text")
            }
        }
        
        private var tagBackgroundColor: Color {
            if isSelected {
                return colorScheme == .dark ? Color("Tags 1") : Color("Background").opacity(0.3)
            } else {
                return colorScheme == .dark ? Color("Tags 1") : Color("Light small text").opacity(0.2)
            }
        }
        
        private var tagTextColor: Color {
            if isSelected {
                return colorScheme == .dark ? Color("Tags words") : Color("Background")
            } else {
                return colorScheme == .dark ? Color("Tags words").opacity(0.9) : Color("Options")
            }
        }
    }
    
    // MARK: - Preview
    struct AI_Questionnaire_View_Previews: PreviewProvider {
        static var previews: some View {
            AI_Questionnaire_View(
                viewModel: AI_Questionnaire_Model(),
                showPrePage: .constant(false)
            )
        }
    }
}
