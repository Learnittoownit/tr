import SwiftUI
import Combine

// MARK: - AI PrePage View
struct AI_PrePage: View {
    @EnvironmentObject private var viewModel: AI_Questionnaire_Model
    @State private var showQuestionnaire = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var onBack: (() -> Void)?
    var goToMain: (() -> Void)? = nil

    // MARK: - Info Row Component
    struct InfoRow: View {
        let icon: String
        let text: String

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("Green"))
                    .frame(width: 24, height: 24)
                Text(text)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Color("Light small text"))
                Spacer()
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
                )
            } else {
                VStack(spacing: 0) {

                    Spacer()

                    // ── HERO SECTION ─────────────────────────────────────
                    VStack(spacing: 16) {
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
                                .frame(width: 160, height: 160)

                            Image(systemName: "sparkles")
                                .font(.system(size: 56, weight: .medium))
                                .foregroundColor(Color("Green"))
                        }

                        Text("Trip Generator")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color("Title"))
                            .multilineTextAlignment(.center)

                        Text("Let our AI create the perfect itinerary just for you!").bold()
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(Color("Light small text"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 40)
                    }

                    Spacer()

                    // ── COUNTER CARD ──────────────────────────────────────
                    VStack(spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("\(viewModel.remainingGenerations)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(Color("Green"))
                            Text("/")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundColor(Color("Light small text").opacity(0.4))
                            Text("5")
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("Light small text").opacity(0.6))
                        }
                        Text("Generations remaining this month")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color("Light small text"))
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(Color("Card"))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color("Card").opacity(0.15), lineWidth: 2)
                    )
                    .padding(.horizontal, 30)

                    Spacer()

                    // ── INFO ROWS ─────────────────────────────────────────
                    VStack(spacing: 16) {
                        InfoRow(icon: "clock.fill",         text: "Takes only 2 minutes")
                        InfoRow(icon: "brain.head.profile", text: "Personalized recommendations")
                        InfoRow(icon: "arrow.clockwise",    text: "Resets monthly")
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 30)

                    Spacer()
                    Spacer()
                }
                .safeAreaInset(edge: .bottom) {
                    // ── BUTTONS ANCHORED TO BOTTOM ────────────────────────
                    VStack(spacing: 12) {
                        Button(action: {
                            if viewModel.remainingGenerations > 0 {
                                viewModel.resetAllAnswers()
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showQuestionnaire = true
                                }
                            }
                        }) {
                            Text("Start")
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
                                .frame(height: 52)
                                .background(Color("Card"))
                                .cornerRadius(26)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
                    .background(Color("Background"))
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
