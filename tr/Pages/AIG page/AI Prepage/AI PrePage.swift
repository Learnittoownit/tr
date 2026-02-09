import SwiftUI
import Combine

// MARK: - AI PrePage View
struct AI_PrePage: View {
    @StateObject private var viewModel = AI_Questionnaire_Model()
    @State private var showQuestionnaire = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
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
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Main Content
                    VStack(spacing: 40) {
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
                            VStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 60, weight: .medium))
                                    .foregroundColor(Color("Green"))
                                
                                Text("AI")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("Title"))
                            }
                        }
                        
                        // Title & Description
                        VStack(spacing: 16) {
                            Text("AI Trip Generator")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color("Title"))
                                .multilineTextAlignment(.center)
                            
                            Text("Let our AI create the perfect itinerary just for you")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(
                                    colorScheme == .dark
                                    ? Color(hex: "CBB7A3") // Dark small text fallback (hex)
                                    : Color("Light small text")
                                )
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        
                        // Generations Remaining Card
                        VStack(spacing: 16) {
                            // Counter Display
                            HStack(spacing: 12) {
                                // Remaining number
                                Text("\(viewModel.remainingGenerations)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("Green"))
                                
                                // Separator
                                Text("/")
                                    .font(.system(size: 32, weight: .medium, design: .rounded))
                                    .foregroundColor(
                                        colorScheme == .dark
                                        ? Color(hex: "CBB7A3")
                                        : Color("Light small text").opacity(0.5)
                                    )
                                
                                // Total number
                                Text("5")
                                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                                    .foregroundColor(
                                        colorScheme == .dark
                                        ? Color(hex: "CBB7A3")
                                        : Color("Light small text").opacity(0.7)
                                    )
                            }
                            
                            Text("Generations remaining this month")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(
                                    colorScheme == .dark
                                    ? Color(hex: "CBB7A3")
                                    : Color("Light small text")
                                )
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, 32)
                        .frame(maxWidth: 320)
                        .background(Color("Card"))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color("Green").opacity(0.2), lineWidth: 2)
                        )
                        
                        // Info Points
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(icon: "clock.fill", text: "Takes only 2 minutes")
                            InfoRow(icon: "brain.head.profile", text: "Personalized recommendations")
                            InfoRow(icon: "arrow.clockwise", text: "Resets monthly")
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    // Bottom Buttons
                    VStack(spacing: 16) {
                        // Start Button
                        // Start Button (نفس منطق Next)
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
                                    ? Color("Next button")                 // ✅ نفس Next
                                    : (colorScheme == .dark
                                        ? Color("Card")                    // Disabled dark
                                        : Color("Background"))             // Disabled light
                            )
                        )
                        .disabled(viewModel.remainingGenerations == 0)

                        
                        // Back Button
                        Button(action: {
                            dismiss()
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
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showQuestionnaire)
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("Green"))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(
                    colorScheme == .dark
                    ? Color(hex: "CBB7A3")
                    : Color("Light small text")
                )
        }
    }
}

// MARK: - Preview
struct AI_PrePage_Previews: PreviewProvider {
    static var previews: some View {
        AI_PrePage()
            .preferredColorScheme(.dark)
    }
}
