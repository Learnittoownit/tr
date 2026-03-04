import SwiftUI
import SwiftData

func getBorderColor(for mainColor: String) -> String {
    let colorMap: [String: String] = [
        "#E0C48A": "#CFB682", "#9FAE8F": "#8E9D7E",
        "#E6B3A2": "#CD9E8E", "#9EC7C0": "#8FB9B2",
        "#B9B2D8": "#AFA7D2"
    ]
    return colorMap[mainColor] ?? mainColor
}

struct TripDetailView: View {
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    let trip: Trip
    @State private var viewModel: TripDetailViewModel?
    @State private var selectedDay: Day?
    @State private var selectedActivity: Activity?
    @State private var showingColorPicker = false

    // Task 9
    @State private var showExtendTrip     = false
    @State private var dayToDelete: Day?  = nil
    @State private var showDeleteDayAlert = false

    // Editable
    @State private var tripName      = ""
    @State private var selectedColor = ""
    @State private var isEditingName = false
    @State private var hasChanges    = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ── Colored Header ────────────────────────────────────────
                ZStack(alignment: .bottom) {
                    Color(hex: selectedColor)
                        .ignoresSafeArea(edges: .top)
                        .frame(height: 135)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Editable Trip Name
                        if isEditingName {
                            TextField("Trip Name", text: $tripName)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .dynamicTypeSize(.large ... .accessibility3)
                                .foregroundStyle(Color(hex: "#3A2F27"))
                                .onSubmit {
                                    isEditingName = false
                                    if tripName != trip.name { hasChanges = true }
                                }
                        } else {
                            Text(tripName)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .dynamicTypeSize(.large ... .accessibility3)
                                .foregroundStyle(Color(hex: "#3A2F27"))
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .onTapGesture { isEditingName = true }
                        }
                        
                        HStack {
                            // Task 9: Tappable date range → opens ExtendTripSheet
                            Button {
                                showExtendTrip = true
                            } label: {
                                HStack(spacing: 5) {
                                    Text(trip.dateRangeString)
                                        .font(.system(size: 15, design: .rounded))
                                        .foregroundStyle(Color(hex: "#5A4A3D"))
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color(hex: "#4A5D4E"))
                                }
                            }
                            
                            Spacer()
                            
                            // Color picker button
                            Button {
                                showingColorPicker = true
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: selectedColor))
                                        .frame(width: 16, height: 16)
                                    Text("Color")
                                        .font(.system(size: 14, design: .rounded))
                                        .dynamicTypeSize(.small ... .large)
                                }
                                .foregroundStyle(Color(hex: "#3A2F27"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(colorScheme == .dark ? Color.white : Color.white.opacity(0.6))
                                .clipShape(Capsule())
                            }
                            .accessibilityLabel("Change trip color")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                // ── Days List ─────────────────────────────────────────────
                ScrollView {
                    VStack(spacing: 16) {
                        if let viewModel = viewModel {
                            ForEach(Array(viewModel.sortedDays.enumerated()), id: \.element.id) { index, day in
                                DayRow(
                                    day: day,
                                    isExpanded: viewModel.isDayExpanded(at: index),
                                    onToggle: { viewModel.toggleDay(at: index) },
                                    onAddActivity: { selectedDay = day },
                                    onEditActivity: { activity in selectedActivity = activity },
                                    onDeleteActivity: { activity in
                                        viewModel.deleteActivity(activity)
                                        hasChanges = true
                                    },
                                    onDeleteDay: {
                                        // Task 9: long press or context menu on day card
                                        dayToDelete = day
                                        showDeleteDayAlert = true
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Text("Back")
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "#3A2F27"))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { saveChanges() } label: {
                    Text("Save")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : (hasChanges ? Color(hex: "#3A2F27") : .gray))
                }
                .disabled(!hasChanges)
            }
        }
        .sheet(item: $selectedDay) { day in
            if let viewModel = viewModel {
                AddActivitySheet(day: day, viewModel: viewModel)
                    .onDisappear { hasChanges = true }
            }
        }
        .sheet(item: $selectedActivity) { activity in
            if let viewModel = viewModel {
                EditActivitySheet(activity: activity, viewModel: viewModel)
                    .onDisappear { hasChanges = true }
            }
        }
        .sheet(isPresented: $showingColorPicker, onDismiss: {
            if selectedColor != trip.colorTheme { hasChanges = true }
        }) {
            TripColorPickerSheet(selectedColor: $selectedColor)
        }
        // Task 9: Extend trip sheet
        .sheet(isPresented: $showExtendTrip) {
            ExtendTripSheet(
                currentStartDate: trip.startDate,
                currentEndDate: trip.endDate
            ) { newEndDate in
                viewModel?.extendTrip(to: newEndDate)
                hasChanges = true
            }
        }
        // Task 9: Delete day confirmation
        .confirmationDialog(
            dayToDelete != nil ? "Delete Day \(dayToDelete!.dayNumber)?" : "Delete Day?",
            isPresented: $showDeleteDayAlert,
            titleVisibility: .visible
        ) {
            Button("Delete Day", role: .destructive) {
                if let day = dayToDelete {
                    viewModel?.deleteDay(day)
                    hasChanges = true
                }
                dayToDelete = nil
            }
            Button("Cancel", role: .cancel) { dayToDelete = nil }
        } message: {
            Text("This will permanently delete the day and all its activities.")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TripDetailViewModel(modelContext: modelContext, trip: trip)
            }
            tripName      = trip.name
            selectedColor = trip.colorTheme
        }
    }
    
    private func saveChanges() {
        trip.name       = tripName
        trip.colorTheme = selectedColor
        trip.updatedAt  = Date()
        do {
            try modelContext.save()
            hasChanges = false
            print("✅ Trip saved")
            dismiss()
        } catch {
            print("❌ Error saving trip: \(error)")
        }
    }
}

// MARK: - Day Row
struct DayRow: View {
    let day: Day
    let isExpanded: Bool
    let onToggle: () -> Void
    let onAddActivity: () -> Void
    let onEditActivity: (Activity) -> Void
    let onDeleteActivity: (Activity) -> Void
    let onDeleteDay: () -> Void               // Task 9

    @ScaledMetric private var dayPadding: CGFloat = 24
    
    var body: some View {
        VStack(spacing: 0) {
            // Day Header
            Button { onToggle() } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(day.dayNumber)")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .dynamicTypeSize(.medium ... .accessibility1)
                            .foregroundStyle(Color(hex: "#3A2F27"))
                            .minimumScaleFactor(0.9)
                        Text(day.dateString)
                            .font(.system(size: 13, design: .rounded))
                            .dynamicTypeSize(.small ... .large)
                            .foregroundStyle(Color(hex: "#7A6A5A"))
                            .minimumScaleFactor(0.9)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#3A2F27"))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, dayPadding)
                .padding(.vertical, 20)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 35))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            // Task 9: long press or context menu to delete day
            .contextMenu {
                Button(role: .destructive) {
                    onDeleteDay()
                } label: {
                    Label("Delete Day", systemImage: "trash")
                }
            }
            .accessibilityLabel("Day \(day.dayNumber), \(day.dateString)")
            .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand and hold to delete")
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(day.sortedActivities) { activity in
                        ActivityCard(
                            activity: activity,
                            onEdit: { onEditActivity(activity) },
                            onDelete: { onDeleteActivity(activity) }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onDeleteActivity(activity)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    Button { onAddActivity() } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Add Activity")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .dynamicTypeSize(.medium ... .accessibility1)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#403029"))
                        .clipShape(RoundedRectangle(cornerRadius: 35))
                    }
                    .accessibilityLabel("Add activity to day \(day.dayNumber)")
                }
                .padding(.top, 12)
            }
        }
    }
}

// MARK: - Activity Card
struct ActivityCard: View {
    let activity: Activity
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.timeString)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .dynamicTypeSize(.small ... .accessibility1)
                        .foregroundStyle(Color(hex: "#3A2F27"))
                        .minimumScaleFactor(0.9)
                    Text(activity.name)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .dynamicTypeSize(.medium ... .accessibility3)
                        .foregroundStyle(Color(hex: "#3A2F27"))
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                    if let notes = activity.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 13, design: .rounded))
                            .dynamicTypeSize(.small ... .accessibility2)
                            .foregroundStyle(Color(hex: "#7A6A5A"))
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                    }
                    if let mapLink = activity.mapLink, !mapLink.isEmpty {
                        Button { openURL(mapLink) } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "link").font(.system(size: 12))
                                Text(mapLink).font(.system(size: 12)).lineLimit(1)
                            }
                            .foregroundStyle(.blue)
                        }
                        .padding(.top, 4)
                    }
                }
                Spacer()
                Button { onEdit() } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "#5A4A3D"))
                }
                .accessibilityLabel("Edit activity")
            }
        }
        .padding(20)
        .background(Color(hex: activity.color).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 35))
        .accessibilityElement(children: .combine)
    }
    
    private func openURL(_ urlString: String) {
        var formatted = urlString
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            formatted = "https://\(urlString)"
        }
        if let url = URL(string: formatted) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Link Badge
struct LinkBadge: View {
    let icon: String
    let color: String
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 10))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(Color(hex: color))
            .clipShape(Circle())
    }
}

// MARK: - Trip Color Picker Sheet
struct TripColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: String
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(Trip.availableThemes, id: \.self) { color in
                        Button { selectedColor = color; dismiss() } label: {
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 60, height: 60)
                                .overlay(Circle().strokeBorder(
                                    selectedColor == color ? Color(hex: "#3A2F27") : Color.clear,
                                    lineWidth: 3
                                ))
                        }
                    }
                }
                .padding(.top, 20)
                Spacer()
            }
            .padding(20)
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        TripDetailView(trip: Trip(
            name: "Summer Adventure",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 3),
            colorTheme: "#F5DEB3"
        ))
    }
    .modelContainer(DatabaseConfig.createPreviewContainer())
}
