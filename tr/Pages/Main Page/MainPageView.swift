//
//  MainPageView.swift
//  tr
//
//  Created by Rama AlQahtani on 17/08/1447 AH.
//
import SwiftUI
import Combine

// MARK: - ViewModel

final class MainPageViewModel: ObservableObject {
    @Published var name: String = "Name"
    @Published var swapped: Bool = false

    func generatePlanTapped() {
        print("Generate Your Plan tapped")
        swapped.toggle()
    }

    func planTripTapped() {
        print("Plan Your Trip tapped")
        swapped.toggle()
    }
}

// MARK: - View

struct MainPage: View {
    @StateObject private var vm = MainPageViewModel()

    // ✅ NAV STATE
    @State private var goToAIPrePage = false

    // exact positions you requested
    private let generatePos = CGPoint(x: 130, y: 350)
    private let planPos = CGPoint(x: 255, y: 600)

    var body: some View {
        NavigationStack {
            ZStack {
                background

                // Header (normal layout)
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 60)
                        .padding(.leading, -170)

                    Spacer()
                }

                // Buttons (absolute layout)
                ZStack {
                    CircleActionButton(
                        title: "Generate\nYour Plan",
                        action: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                vm.generatePlanTapped()
                            }

                            // ✅ NAVIGATE
                            goToAIPrePage = true
                        }
                    )
                    .frame(width: 260, height: 240)
                    .position(vm.swapped ? planPos : generatePos)

                    CircleActionButton(
                        title: "Plan\nYour Trip",
                        action: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                vm.planTripTapped()
                            }
                        }
                    )
                    .frame(width: 260, height: 240)
                    .position(vm.swapped ? generatePos : planPos)
                }
            }
            .ignoresSafeArea()

            // ✅ DESTINATION
            .navigationDestination(isPresented: $goToAIPrePage) {
                AI_PrePage() // <-- change to your real view name
            }
        }
    }
}

// MARK: - Button Component

struct CircleActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color("Green"))
                    .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)

                LiquidGlassText(title: title)
                    .padding(.horizontal, 16)
            }
        }
        .buttonStyle(CirclePressStyle())
        .contentShape(Circle())
    }
}

// MARK: - Press Style

struct CirclePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                Circle()
                    .fill(Color("Button click"))
                    .opacity(configuration.isPressed ? 0.18 : 0.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - LiquidGlassText

struct LiquidGlassText: View {
    let title: String

    var body: some View {
        let text = Text(title)
            .font(.system(size: 35, weight: .heavy, design: .rounded))
            .multilineTextAlignment(.center)

        if #available(iOS 26.0, *) {
            Rectangle()
                .fill(.clear)
                .glassEffect(.regular.interactive(), in: Rectangle())
                .mask(text.foregroundStyle(.white))
                .overlay(
                    text
                        .foregroundStyle(.white.opacity(0.18))
                        .blendMode(.overlay)
                )
        } else {
            text.foregroundStyle(Color("Light small text"))
        }
    }
}

// MARK: - UI Pieces

private extension MainPage {
    var header: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("Dark small text"))
                .frame(width: 10, height: 34)

            Text("Hi \(vm.name)")
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(Color("Title"))
        }
    }

    var background: some View {
        ZStack {
            Color("Background")

            RadialGradient(
                colors: [
                    Color("Title").opacity(0.20),
                    .clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 200
            )

            RadialGradient(
                colors: [
                    Color("Background").opacity(0.18),
                    .clear
                ],
                center: UnitPoint(x: 0.6, y: 0.7),
                startRadius: 20,
                endRadius: 360
            )
        }
    }
}

// MARK: - Preview

#Preview {
    MainPage()
}
