import SwiftUI
import Combine

// MARK: - AI PrePage View
struct AI_PrePage: View {
    @EnvironmentObject private var viewModel: AI_Questionnaire_Model
    @State private var showQuestionnaire = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    
    var onBack: (() -> Void)?
    var goToMain: (() -> Void)? = nil   // ← ADD
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
                    .foregroundColor(Color("Light small text"))
            }
        }
    }

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
                
            if showQuestionnaire {
                AI_Questionnaire_View(
                    viewModel: viewModel,
                    showPrePage: $showQuestionnaire,
                    goToMain: goToMain
                )            } else {
                VStack(spacing: 35) {
                    Spacer()
                    
                    VStack(spacing: 25) {
                        // Icon
                        ZStack {
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
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundColor(Color("Green"))
                        }
                        
                        // Title & Description
                        VStack(spacing: 15) {
                            Text("AI Trip Generator")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color("Title"))
                                .multilineTextAlignment(.center)
                            
                            Text("Let our AI create the perfect itinerary just for you")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(Color("Light small text"))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        
                        // Generations Counter Card
                        VStack(spacing: 15) {
                            HStack(spacing: 18) {
                                Text("\(viewModel.remainingGenerations)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("Green"))
                                
                                Text("/")
                                    .font(.system(size: 32, weight: .medium, design: .rounded))
                                    .foregroundColor(Color("Light small text").opacity(0.5))
                                
                                Text("5")
                                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color("Light small text").opacity(0.7))
                            }
                            
                            Text("Generations remaining this month")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(Color("Light small text"))
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
                        
                        // Info Points
                        VStack(alignment: .leading, spacing: 18) {
                            InfoRow(icon: "clock.fill",         text: "Takes only 2 minutes")
                            InfoRow(icon: "brain.head.profile", text: "Personalized recommendations")
                            InfoRow(icon: "arrow.clockwise",    text: "Resets monthly")
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 22)
                    }
                    
                    Spacer()
                    
                    // Bottom Buttons
                    VStack(spacing: 10) {
                        // Start Button
                        Button(action: {
                            if viewModel.remainingGenerations > 0 {
                                viewModel.resetAllAnswers()
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showQuestionnaire = true
                                }
                            }
                        }) {
                            Text("Start AI Generator")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("Background"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .buttonStyle(
                            PressableNextButtonStyle(
                                pressedColor: Color("Next button"),
                                normalColor: Color("Next button")
                            )
                        )
                        .opacity(viewModel.remainingGenerations > 0 ? 1.0 : 0.4)
                        .disabled(viewModel.remainingGenerations == 0)

                        // Back Button
                        Button(action: {
                            if let onBack {
                                onBack()
                            } else {
                                Task { @MainActor in
                                    dismiss()
                                }
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
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview
struct AI_PrePage_Previews: PreviewProvider {
    static var previews: some View {
        AI_PrePage()
            .environmentObject(AI_Questionnaire_Model())
    }
}
