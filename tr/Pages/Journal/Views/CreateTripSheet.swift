import SwiftUI
import SwiftData

struct CreateTripSheet: View {
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    let viewModel: JournalViewModel
    var onTripCreated: ((Trip) -> Void)? = nil

    // MARK: - State
    @State private var tripName = ""
    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil
    @State private var selectedColor = "#CCBFB7"
    @State private var showingDurationPicker = false
    @State private var showingColorPicker = false
    
    // MARK: - Computed Properties
    private var isValidTrip: Bool {
        guard !tripName.isEmpty, let start = startDate, let end = endDate else { return false }
        return durationInDays >= 1
    }
    
    private var durationInDays: Int {
        guard let start = startDate, let end = endDate else { return 0 }
        return (Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }
    
    private var durationText: String {
        guard startDate != nil && endDate != nil else { return "Select dates" }
        return durationInDays == 1 ? "1 day" : "\(durationInDays) days"
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: selectedColor).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 20) {

                        ZStack(alignment: .leading) {
                            if tripName.isEmpty {
                                Text("Trip Name..")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(placeholderColor)
                                    .accessibilityHidden(true)
                            }
                            TextField("", text: $tripName)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#3A2F27"))
                                .accessibilityLabel("Trip Name")
                        }

                        HStack {
                            Button {
                                showingDurationPicker = true
                            } label: {
                                HStack(spacing: 6) {
                                    Text(durationText)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(Color(hex: "#3A2F27"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.6))
                                .clipShape(Capsule())
                            }

                            Spacer()

                            Button {
                                showingColorPicker = true
                            } label: {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(hex: selectedColor))
                                        .frame(width: 14, height: 14)
                                    Text("Color")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(Color(hex: "#3A2F27"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.6))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)

                    Color("jsavebutton").ignoresSafeArea()
                }
            }
            .navigationTitle("Create Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color(hex: "#3A2F27"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createTrip() }
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(isValidTrip ? Color(hex: "#3A2F27") : .gray)
                        .disabled(!isValidTrip)
                }
            }
            .sheet(isPresented: $showingDurationPicker) {
                DurationPickerSheet(startDate: $startDate, endDate: $endDate)
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerSheet(selectedColor: $selectedColor)
            }
        }
    }
    
    private var placeholderColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.8)
            : Color(hex: "#3A2F27").opacity(0.75)
    }
    
    private func createTrip() {
        guard let start = startDate, let end = endDate, start <= end else { return }
        let newTrip = viewModel.createTrip(
            name: tripName, startDate: start, endDate: end, colorTheme: selectedColor
        )
        dismiss()
        onTripCreated?(newTrip)
    }
}

// MARK: - Duration Picker Sheet (Graphical Calendar)
struct DurationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var startDate: Date?
    @Binding var endDate: Date?

    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    @State private var pickingStart = true   // true = user is picking start, false = end

    private let brown = Color(hex: "#3A2F27")
    private let green = Color(hex: "#4A5D4E")
    private let cream = Color(hex: "#FAF4EC")

    init(startDate: Binding<Date?>, endDate: Binding<Date?>) {
        self._startDate = startDate
        self._endDate   = endDate
        let start = startDate.wrappedValue ?? Date()
        let end   = endDate.wrappedValue ?? Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        self._tempStartDate = State(initialValue: start)
        self._tempEndDate   = State(initialValue: max(start, end))
    }

    private var durationDays: Int {
        max(1, (Calendar.current.dateComponents([.day], from: tempStartDate, to: tempEndDate).day ?? 0) + 1)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── From / To toggle ──────────────────────────────────
                    HStack(spacing: 12) {
                        // From pill
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { pickingStart = true }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("From")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(brown.opacity(0.55))
                                Text(formatDate(tempStartDate))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(brown)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(pickingStart ? brown.opacity(0.12) : Color("Card"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(pickingStart ? green : Color.clear, lineWidth: 2)
                            )
                        }

                        // Arrow
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(brown.opacity(0.4))

                        // To pill
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { pickingStart = false }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("To")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(brown.opacity(0.55))
                                Text(formatDate(tempEndDate))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(brown)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(!pickingStart ? brown.opacity(0.12) : Color("Card"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(!pickingStart ? green : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Duration pill
                    Text("\(durationDays) day\(durationDays == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(green)
                        .clipShape(Capsule())
                        .padding(.top, 12)

                    // ── Calendar ──────────────────────────────────────────
                    if pickingStart {
                        DatePicker(
                            "Start date",
                            selection: $tempStartDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(green)
                        .padding(.horizontal, 8)
                        .onChange(of: tempStartDate) { _, new in
                            // Keep end date valid
                            if tempEndDate < new {
                                tempEndDate = new
                            }
                            // Auto-advance to picking end
                            withAnimation(.easeInOut(duration: 0.3)) { pickingStart = false }
                        }
                    } else {
                        DatePicker(
                            "End date",
                            selection: $tempEndDate,
                            in: tempStartDate...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(green)
                        .padding(.horizontal, 8)
                    }

                    Spacer()

                    // ── Done button ───────────────────────────────────────
                    Button {
                        startDate = tempStartDate
                        endDate   = tempEndDate
                        dismiss()
                    } label: {
                        Text("Confirm \(durationDays) Day\(durationDays == 1 ? "" : "s")")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(cream)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(brown)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Select Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : brown)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }
}

// MARK: - Color Picker Sheet
struct ColorPickerSheet: View {
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
    let container = DatabaseConfig.createPreviewContainer()
    let viewModel = JournalViewModel(modelContext: container.mainContext)
    return CreateTripSheet(viewModel: viewModel).modelContainer(container)
}
