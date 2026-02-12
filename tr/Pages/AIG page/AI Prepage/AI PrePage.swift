import SwiftUI
import Combine

// MARK: - AI PrePage View
struct AI_PrePage: View {
    @StateObject private var viewModel = AI_Questionnaire_Model()
    @State private var showQuestionnaire = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Info Row Component
    struct InfoRow: View {
        let icon: String
        let text: String
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("Green"))
                    .frame(width: 24)
                
                Text(text)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(
                        Color("Light small text")
                    )
            }
        }
    }
    var body: some View {
        ZStack {
            // Background
            Color("Background")
                .ignoresSafeArea()
                
            if showQuestionnaire {
                // Show Questionnaire Flow
                AI_Questionnaire_View(viewModel: viewModel, showPrePage: $showQuestionnaire)
                    .transition(.opacity)
            } else {
                // PrePage Content
                VStack(spacing: 35) {
                    Spacer()
                    
                    // Main Content
                    VStack(spacing: 25) {
                        // Icon/Visual
                        ZStack {
                            // Gradient Circle Background
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color("Green").opacity(0.2),
                                            Color("Green").opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 180, height: 180)
                            
                            // AI Sparkle Icon
                            VStack(spacing: 15) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 60, weight: .medium))
                                    .foregroundColor(Color("Green"))
                                
                                
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("Title"))
                            }
                        }
                        
                        // Title & Description
                        VStack(spacing: 15) {
                            Text("AI Trip Generator")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color("Title"))
                                .multilineTextAlignment(.center)
                            
                            Text("Let our AI create the perfect itinerary just for you")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(
                                    
                                    Color("Light small text")
                                )
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        
                        // Generations Remaining Card
                        VStack(spacing: 15) {
                            // Counter Display
                            HStack(spacing: 18) {
                                // Remaining number
                                Text("\(viewModel.remainingGenerations)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("Green"))
                                
                                // Separator
                                Text("/")
                                    .font(.system(size: 32, weight: .medium, design: .rounded))
                                    .foregroundColor(
                                        Color("Light small text").opacity(0.5)
                                    )
                                
                                // Total number
                                Text("5")
                                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                                    .foregroundColor(
                                        
                                        Color("Light small text").opacity(0.7)
                                    )
                            }
                            
                            Text("Generations remaining this month")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(
                                    Color("Light small text")
                                )
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 32)
                        .frame(maxWidth: 320)
                        .background(Color("Card"))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color("Card").opacity(0.15), lineWidth: 2)
                        )
                        
                        // Info Points (adjusted spacing here only)
                        VStack(alignment: .leading, spacing: 18) {
                            InfoRow(icon: "clock.fill", text: "Takes only 2 minutes")
                            InfoRow(icon: "brain.head.profile", text: "Personalized recommendations")
                            InfoRow(icon: "arrow.clockwise", text: "Resets monthly")
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 22) // زودنا المسافة هنا
                    }
                    
                    Spacer()
                    
                    
                    // Bottom Buttons
                    VStack(spacing: 10) {
                        Button(action: {
                            if viewModel.remainingGenerations > 0 {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showQuestionnaire = true
                                }
                            }
                        }) {
                            Text("Start AI Generator")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(
                                    viewModel.remainingGenerations > 0
                                    ? Color("Background")
                                    : (colorScheme == .dark ? .white : Color("Title"))
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .buttonStyle(
                            PressableNextButtonStyle(
                                pressedColor: Color("Next button"),
                                normalColor: viewModel.remainingGenerations > 0
                                ? Color("Next button")
                                : (colorScheme == .dark ? Color("Card") : Color("Background"))
                            )
                        )
                        .disabled(viewModel.remainingGenerations == 0)
                        // Back Button
                        Button(action: {
                            Task { @MainActor in
                                dismiss()
                            }
                        }) {
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("Title"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color("Card"))
                                .cornerRadius(25)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
        }
        // Hide system back button for this screen
        .navigationBarBackButtonHidden(true)
    }
}


// MARK: - Preview
struct AI_PrePage_Previews: PreviewProvider {
    static var previews: some View {
        AI_PrePage()
    }
}
