import SwiftUI
import Combine

// MARK: - AI Plan View
struct AI_Plan_View: View {
    @ObservedObject var viewModel: AI_Questionnaire_Model
    @Binding var showPrePage: Bool
    @State private var expandedDays: Set<Int> = [1] // First day expanded by default
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color("Background")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Title Card
                        titleCard
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                        
                        // Days
                        VStack(spacing: 16) {
                            if let trip = viewModel.generatedTrip {
                                ForEach(trip.days) { day in
                                    DayCardView(
                                        day: day,
                                        isExpanded: expandedDays.contains(day.dayNumber)
                                    ) {
                                        toggleDay(day.dayNumber)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 120)
                    }
                }
            }
            
            // Bottom Button
            VStack {
                Spacer()
                saveButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                // ✅ FIXED: Go back to PrePage
                withAnimation {
                    viewModel.resetToPrePage()
                    showPrePage = false
                }
            }) {
                Text("Back")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(Color("Title"))
            }
            
            Spacer()
            
            Text("AI Plan")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color("Title"))
            
            Spacer()
            
            // Placeholder for symmetry
            Text("Back")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.clear)
        }
    }
    
    private var titleCard: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("\(viewModel.generatedTrip?.cityName ?? "City") journey")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(Color("Title"))
                .multilineTextAlignment(.center)
            
            Text("Save it to journal to have the privilege\nto edit it!")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(Color("Light small text"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color("Card"))
        .cornerRadius(24)
    }
    
    private var saveButton: some View {
        Button(action: {
            // Save to journal action
            print("Saving to journal...")
        }) {
            Text("Save to journal")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color("Button click"))
                .cornerRadius(28)
        }
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
    }
    
    private func toggleDay(_ dayNumber: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if expandedDays.contains(dayNumber) {
                expandedDays.remove(dayNumber)
            } else {
                expandedDays.insert(dayNumber)
            }
        }
    }
}

// MARK: - Day Card View
struct DayCardView: View {
    let day: GeneratedDay
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Day Header
            Button(action: onToggle) {
                HStack {
                    Text("Day \(day.dayNumber)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color("Title"))
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("Title"))
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
            
            // Activities (when expanded)
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(day.activities) { activity in
                        ActivityCardView(activity: activity)
                    }
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
    }
}

// MARK: - Activity Card View
struct ActivityCardView: View {
    let activity: GeneratedActivity
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time
            Text(activity.time)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color("Title"))
                .frame(width: 75, alignment: .leading)
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Activity Name (✅ REMOVED EDIT BUTTON - can't edit until saved to journal)
                Text(activity.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color("Title"))
                    .frame(maxWidth: .infinity, alignment: .leading) // ✅ FIXED: Full width
                
                // Description
                Text(activity.description)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Color("Light small text"))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading) // ✅ FIXED: Full width
                
                // Links
                if !activity.links.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(activity.links.indices, id: \.self) { index in
                            Link(destination: URL(string: activity.links[index].url) ?? URL(string: "https://google.com")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                        .font(.system(size: 11))
                                    
                                    Text(activity.links[index].displayText)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .lineLimit(1)
                                }
                                .foregroundColor(Color("Green"))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading) // ✅ FIXED: Full width
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading) // ✅ FIXED: Content takes full width
        }
        .frame(maxWidth: .infinity) // ✅ FIXED: Card takes full width
        .padding(16)
        .background(Color("Green").opacity(0.15))
        .cornerRadius(20)
    }
}

// MARK: - Preview
struct AI_Plan_View_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AI_Questionnaire_Model()
        
        // Create mock data
        viewModel.generatedTrip = GeneratedTrip(
            cityName: "Riyadh",
            days: [
                GeneratedDay(
                    dayNumber: 1,
                    activities: [
                        GeneratedActivity(
                            time: "9:00 AM",
                            name: "Billy Brunch",
                            description: "Don't Forget to check on ....",
                            links: [
                                ActivityLink(url: "https://maps.google.com", displayText: "https://maps.app.goo.gl/rMtD3jZL6w2yjK9Q5B")
                            ]
                        ),
                        GeneratedActivity(
                            time: "1:00 PM",
                            name: "Costa Brave",
                            description: "Notes that was added by the user",
                            links: [
                                ActivityLink(url: "https://booking.com", displayText: "Link if it was added")
                            ]
                        )
                    ],
                    isExpanded: true
                ),
                GeneratedDay(
                    dayNumber: 2,
                    activities: [
                        GeneratedActivity(
                            time: "10:00 AM",
                            name: "Museum Visit",
                            description: "Explore local heritage",
                            links: []
                        )
                    ],
                    isExpanded: false
                )
            ]
        )
        viewModel.showGeneratedPlan = true
        
        return AI_Plan_View(viewModel: viewModel, showPrePage: .constant(false))
    }
}
