import SwiftUI
import Combine
import SwiftData

// MARK: - AI Plan View
struct AI_Plan_View: View {
    @ObservedObject var viewModel: AI_Questionnaire_Model
    @Binding var showPrePage: Bool
    @State private var expandedDays: Set<Int> = [1]
    @State private var isSaved: Bool = false
    @State private var navigateToJournal: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    var onSaveToJournal: () -> Void
    var goToMain: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Extended colored header (like Journal)
                ZStack(alignment: .bottom) {
                    Color("AIG BACK")
                        .ignoresSafeArea(edges: .top)
                        .frame(height: 135)
                    
                    VStack(alignment: .center, spacing: 12) {
                        Text("\(viewModel.generatedTrip?.cityName ?? "City") Journey")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(Color("Title"))
                            .multilineTextAlignment(.center)

                        Text("Save it to journal to edit it anytime!").bold()
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(Color("Light small text"))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                }

                // Days list
                ScrollView(showsIndicators: false) {
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

            VStack {
                Spacer()
                saveButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("AI Plan").bold()
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("AI plan"))
            }
            
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation {
                        viewModel.resetToPrePage()
                        showPrePage = false
                    }
                } label: {
                    Text("Back")
                        .font(.system(size: 17, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : Color("Title"))
                }
            }
        }
        .navigationDestination(isPresented: $navigateToJournal) {
            JournalView(onBack: {
                navigateToJournal = false
                viewModel.resetToPrePage()
                showPrePage = false
                goToMain?()
            })
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: {
            guard !isSaved else { return }
            isSaved = true

            if let savedTrip = viewModel.saveToJournal(modelContext: modelContext) {
                print("✅ Trip saved: \(savedTrip.name)")
                onSaveToJournal()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    navigateToJournal = true
                }
            } else {
                print("❌ Failed to save trip")
                isSaved = false
            }
        }) {
            HStack(spacing: 10) {
                if isSaved {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color("select"))
                }
                Text(isSaved ? "Saved!" : "Save to Journal")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("select"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isSaved ? Color("Button click").opacity(0.5) : Color("Button click"))
            .cornerRadius(28)
            .animation(.easeInOut(duration: 0.2), value: isSaved)
        }
        .disabled(isSaved)
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
                .padding(.horizontal, 24)
                .padding(.vertical, 26)
                .background(Color("Card"))
                .cornerRadius(35)
            }
            .buttonStyle(.plain)

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
    @State private var isExpanded: Bool = false
    private let descriptionLineLimit = 3

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(activity.time)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color("Title"))
                .frame(width: 75, alignment: .leading)

            VStack(alignment: .leading, spacing: 10) {
                Text(activity.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color("Title"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Color("Light small text"))
                        .lineLimit(isExpanded ? nil : descriptionLineLimit)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if activity.description.count > 100 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isExpanded ? "Show less" : "Show more")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(Color("Green"))
                        }
                    }
                }

                if !activity.links.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(activity.links.indices, id: \.self) { index in
                            let link = activity.links[index]
                            Link(destination: URL(string: link.url) ?? URL(string: "https://google.com")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: iconFor(label: link.displayText))
                                        .font(.system(size: 11, weight: .semibold))
                                    Text(link.displayText)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .lineLimit(1)
                                }
                                .foregroundColor(Color("Green"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color("Green").opacity(0.12))
                                .cornerRadius(20)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color("Green").opacity(0.15))
        .cornerRadius(20)
    }

    private func iconFor(label: String) -> String {
        let l = label.lowercased()
        if l.contains("instagram")                                          { return "camera.fill" }
        if l.contains("book") || l.contains("reserve") || l.contains("table") { return "calendar.badge.plus" }
        if l.contains("map")                                                { return "map.fill" }
        if l.contains("website") || l.contains("official")                  { return "globe" }
        if l.contains("whatsapp")                                           { return "phone.fill" }
        if l.contains("tiktok")                                             { return "play.circle.fill" }
        if l.contains("ticket")                                             { return "ticket.fill" }
        return "link"
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { row in
            row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        }.reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var rowWidth: CGFloat = 0
        let maxWidth = proposal.width ?? 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(subview)
            rowWidth += size.width + spacing
        }
        return rows
    }
}
