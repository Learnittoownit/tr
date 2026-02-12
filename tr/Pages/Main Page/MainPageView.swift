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

// MARK: - Routing (بدون NavigationStack)

private enum MainRoute {
    case main
    case aiPrePage
    case journal
}

// MARK: - View

struct MainPage: View {
    @StateObject private var vm = MainPageViewModel()
    @Environment(\.colorScheme) var colorScheme

    // ✅ ROUTE STATE بدل NavigationStack
    @State private var route: MainRoute = .main
    @State private var appeared = false

    var body: some View {
        ZStack {
            switch route {
            case .main:
                mainContent
            case .aiPrePage:
                // استبدل بـ AI_PrePage() عندما تكون متوفرة
                AI_PrePage()
                    .transition(.identity) // لا انتقال
            case .journal:
                // استبدل بـ JournalView() عندما تكون متوفرة
                JournalView()
                    .transition(.identity) // لا انتقال
            }
        }
        // منع أي أنيميشن ضمن تغييرات الحالة
        .animation(nil, value: route)
    }

    // شاشة الرئيسية (الأزرار)
    private var mainContent: some View {
        ZStack {
            background

            VStack {
                // Header
                HStack {
                    header
                        .padding(.top, 90)
                        .padding(.leading, 80)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -20)

                    Spacer()
                }

                Spacer()

                // Bottom subtitle
                subtitle
                    .padding(.bottom, 60)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }

            // Buttons
            GeometryReader { geometry in
                let leftX = geometry.size.width * 0.35
                let rightX = geometry.size.width * 0.65
                let generateY: CGFloat = 320
                let planY: CGFloat = 570

                ZStack {
                    CircleActionButton(
                        title: "Generate Your Plan",
                        icon: "sparkles",
                        titleOffsetY: -10,
                        iconOffsetY: 8,
                        action: {
                            // حركة الزر (بصرية فقط)
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                vm.generatePlanTapped()
                            }
                            // ✅ انتقال فوري بتغيير الحالة مباشرة (لا NavigationStack)
                            route = .aiPrePage
                        }
                    )
                    .frame(width: 250, height: 250)
                    .position(
                        x: vm.swapped ? rightX : leftX,
                        y: vm.swapped ? planY : generateY
                    )
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.8)

                    CircleActionButton(
                        title: "Plan Your Trip",
                        icon: "map.fill",
                        titleOffsetY: -6,
                        iconOffsetY: 8,
                        action: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                vm.planTripTapped()
                            }
                            // ✅ انتقال فوري بتغيير الحالة مباشرة (لا NavigationStack)
                            route = .journal
                        }
                    )
                    .frame(width: 250, height: 250)
                    .position(
                        x: vm.swapped ? leftX : rightX,
                        y: vm.swapped ? generateY : planY
                    )
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.8)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        // تعطيل أي أنيميشن ضمن هذه الشاشة
        .transaction { t in t.animation = nil }
    }
}

// MARK: - Button Component

struct CircleActionButton: View {
    let title: String
    let icon: String
    var titleOffsetY: CGFloat = 0
    var iconOffsetY: CGFloat = 0
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        colorScheme == .dark
                        ? Color("Green").opacity(0.4)
                        : Color("Green").opacity(0.2)
                    )
                    .blur(radius: 20)
                    .scaleEffect(isHovering ? 1.1 : 1.0)

                // Main circle
                Circle()
                    .fill(
                        colorScheme == .dark
                        ? Color("Green").opacity(0.95)
                        : Color("Green")
                    )
                    .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 8)

                // Shimmer overlay
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.5),
                                .clear,
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)

                VStack(spacing: 4) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.25))
                            .frame(width: 60, height: 63)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.3),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)

                        Image(systemName: icon)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .offset(y: iconOffsetY)

                    LiquidGlassText(title: title)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .offset(y: titleOffsetY)
                }
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
                    .opacity(configuration.isPressed ? 0.25 : 0.0)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - LiquidGlassText

struct LiquidGlassText: View {
    let title: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let text = Text(title)
            .font(.system(size: 34, weight: .heavy, design: .rounded))
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
            text.foregroundStyle(
                colorScheme == .dark
                ? Color.white.opacity(0.95)
                : Color("Dark small text")
            )
        }
    }
}

// MARK: - UI Pieces

private extension MainPage {
    var header: some View {
        HStack(spacing: 12) { }
    }

    var subtitle: some View {
        VStack(spacing: 6) {
            Text("Choose your journey")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("Title").opacity(0.7))

            Text("Tap a circle to get started")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color("Title").opacity(0.5))
        }
    }

    var background: some View {
        ZStack {
            Color("Background")

            RadialGradient(
                colors: [
                    Color("Title").opacity(0.25),
                    .clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 250
            )

            RadialGradient(
                colors: [
                    Color("Green").opacity(0.15),
                    .clear
                ],
                center: UnitPoint(x: 0.3, y: 0.4),
                startRadius: 30,
                endRadius: 300
            )

            RadialGradient(
                colors: [
                    Color("Background").opacity(0.2),
                    .clear
                ],
                center: UnitPoint(x: 0.7, y: 0.7),
                startRadius: 20,
                endRadius: 380
            )
        }
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    MainPage()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    MainPage()
        .preferredColorScheme(.dark)
}
