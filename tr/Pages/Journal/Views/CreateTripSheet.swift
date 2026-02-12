import SwiftUI
import SwiftData

struct CreateTripSheet: View {
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    let viewModel: JournalViewModel  // ✅ Receive viewModel from parent!

    
    // MARK: - State
    @State private var tripName = ""
    @State private var startDate: Date? = nil  // No pre-selected dates
    @State private var endDate: Date? = nil    // No pre-selected dates
    @State private var selectedColor = "#CCBFB7" // Default color
    @State private var showingDurationPicker = false
    @State private var showingColorPicker = false
    
    // MARK: - Computed Properties
    private var isValidTrip: Bool {
        guard !tripName.isEmpty,
              let start = startDate,
              let end = endDate else {
            return false
        }
        
        let days = durationInDays
        return days >= 1
    }
    
    private var durationInDays: Int {
        guard let start = startDate, let end = endDate else {
            return 0
        }
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        return days + 1  // Include both start and end day
    }
    
    private var durationText: String {
        guard startDate != nil && endDate != nil else {
            return "Select dates"
        }
        
        let days = durationInDays
        if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background with selected color
               Color("Header")

                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header section with colored background
                    VStack(spacing: 20) {
                        // Trip Name Input
                        TextField("Trip Name..", text: $tripName)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#3A2F27"))
                            .multilineTextAlignment(.leading)
                        
                        // Duration and Color buttons
                        HStack(spacing: 12) {
                            // Duration Button
                            Button {
                                showingDurationPicker = true
                            } label: {
                                HStack {
                                    Text(durationText)
                                        .font(.system(size: 15, design: .rounded))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, design: .rounded))
                                }
                                .foregroundStyle(Color(hex: "#3A2F27"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.6))
                                .clipShape(Capsule())
                            }
                            
                            // Color Button
                            Button {
                                showingColorPicker = true
                            } label: {
                                HStack {
                                    Text("Color")
                                        .font(.system(size: 15, design: .rounded))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, design: .rounded))
                                }
                                .foregroundStyle(Color(hex: "#3A2F27"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.6))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(20)
                    
                    Color("jsavebutton")
                        .ignoresSafeArea()
           

                }
            }
            .navigationTitle("Create Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .font(.system(size: 17, design: .rounded))
                    .foregroundStyle(Color(hex: "#3A2F27"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTrip()
                    }
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(isValidTrip ? Color(hex: "#3A2F27") : .gray)
                    .disabled(!isValidTrip)
                }
            }
            .sheet(isPresented: $showingDurationPicker) {
                DurationPickerSheet(
                    startDate: $startDate,
                    endDate: $endDate
                )
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerSheet(selectedColor: $selectedColor)
            }
        }
    }
    
    // MARK: - Methods
    private func createTrip() {
        guard let start = startDate, let end = endDate else {
            print("❌ Invalid dates")
            return
        }
        
        // Safety check
        guard start <= end else {
            print("❌ Start date must be before or equal to end date")
            return
        }
        
        _ = viewModel.createTrip(
            name: tripName,
            startDate: start,
            endDate: end,
            colorTheme: selectedColor
        )
        
        // Dismiss sheet and go back to JournalView
        dismiss()
        
        print("✅ Trip created: \(tripName)")
    }
}

// MARK: - Duration Picker Sheet
struct DurationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    
    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    
    init(startDate: Binding<Date?>, endDate: Binding<Date?>) {
        self._startDate = startDate
        self._endDate = endDate
        
        let start = startDate.wrappedValue ?? Date()
        let end = endDate.wrappedValue ?? Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        
        self._tempStartDate = State(initialValue: start)
        self._tempEndDate = State(initialValue: max(start, end))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Compact Date Pickers
                VStack(alignment: .leading, spacing: 16) {
                    // Start Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.gray)
                        
                        DatePicker(
                            "Start Date",
                            selection: $tempStartDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .onChange(of: tempStartDate) { _, newValue in
                            if tempEndDate < newValue {
                                tempEndDate = newValue
                            }
                        }
                    }
                    
                    Divider()
                    
                    // End Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.gray)
                        
                        DatePicker(
                            "End Date",
                            selection: $tempEndDate,
                            in: tempStartDate...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
            .navigationTitle("Select Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 17, design: .rounded))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        startDate = tempStartDate
                        endDate = tempEndDate
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Color Picker Sheet
struct ColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: String
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(Trip.availableThemes, id: \.self) { color in
                        Button {
                            selectedColor = color
                            dismiss()
                        } label: {
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            selectedColor == color ? Color(hex: "#3A2F27") : Color.clear,
                                            lineWidth: 3
                                        )
                                )
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
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview
#Preview {
    let container = DatabaseConfig.createPreviewContainer()
    let viewModel = JournalViewModel(modelContext: container.mainContext)
    
    return CreateTripSheet(viewModel: viewModel)
        .modelContainer(container)
}
