import SwiftUI
import SwiftData

struct EditActivitySheet: View {
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Properties
    let activity: Activity
    let viewModel: TripDetailViewModel?
    
    // MARK: - State
    @State private var activityName: String
    @State private var selectedTime: Date
    @State private var placeName: String
    @State private var notes: String
    @State private var mapLink: String
    @State private var selectedColor: String
    
    // MARK: - Scaled Metrics
    @ScaledMetric private var inputPadding: CGFloat = 16
    @ScaledMetric private var sectionSpacing: CGFloat = 16
    
    // MARK: - Available Colors
    private let availableColors = ["#E0C48A", "#9FAE8F", "#E6B3A2", "#9EC7C0", "#B9B2D8"]
    private let borderColors = ["#CFB682", "#8E9D7E", "#CD9E8E", "#8FB9B2", "#AFA7D2"]
    
    private let brown = Color(hex: "#3A2F27")
    private let softRed = Color(red: 0.72, green: 0.25, blue: 0.20) // muted red
    
    // MARK: - Initialization
    init(activity: Activity, viewModel: TripDetailViewModel?) {
        self.activity = activity
        self.viewModel = viewModel
        _activityName = State(initialValue: activity.name)
        _selectedTime = State(initialValue: activity.time)
        _placeName    = State(initialValue: activity.placeName ?? "")
        _notes        = State(initialValue: activity.notes ?? "")
        _mapLink      = State(initialValue: activity.mapLink ?? "")
        _selectedColor = State(initialValue: activity.color)
    }
    
    private var isValidActivity: Bool { !activityName.isEmpty }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: sectionSpacing) {
                            inputField(placeholder: "Name of Place...", text: $activityName)
                            timePicker
                            linksSection
                            notesField
                            colorPicker
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 260)
                    }
                    bottomButtons
                }
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(colorScheme == .dark ? .white : brown)
                }
            }
        }
    }
    
    // MARK: - Input Field
    private func inputField(placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(Color("Color 1").opacity(0.6))
                    .padding(.horizontal, 20)
            }
            TextField("", text: text)
                .font(.system(size: 16, design: .rounded))
                .dynamicTypeSize(.medium ... .accessibility2)
                .foregroundStyle(Color("Color 1"))
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color("InputField"))
        .clipShape(RoundedRectangle(cornerRadius: 35))
    }
    
    // MARK: - Time Picker
    private var timePicker: some View {
        HStack {
            Text("Time")
                .font(.system(size: 16, design: .rounded))
                .dynamicTypeSize(.medium ... .accessibility1)
                .foregroundStyle(Color("Color 1"))
            Spacer()
            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Color("Color 1"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color("InputField"))
        .clipShape(RoundedRectangle(cornerRadius: 35))
    }
    
    // MARK: - Links Section
    private var linksSection: some View {
        ZStack(alignment: .leading) {
            if mapLink.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 14))
                        .foregroundStyle(Color("Color 1").opacity(0.6))
                        .accessibilityHidden(true)
                    Text("Map, Menu, Booking...")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(Color("Color 1").opacity(0.6))
                }
                .padding(.horizontal, 20)
            }
            HStack {
                Image(systemName: "link")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                    .accessibilityHidden(true)
                TextField("", text: $mapLink)
                    .font(.system(size: 15, design: .rounded))
                    .dynamicTypeSize(.small ... .accessibility2)
                    .foregroundStyle(Color("Color 1"))
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color("InputField"))
        .clipShape(RoundedRectangle(cornerRadius: 35))
    }
    
    // MARK: - Notes Field
    private var notesField: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $notes)
                .font(.system(size: 15, design: .rounded))
                .dynamicTypeSize(.small ... .accessibility2)
                .foregroundStyle(Color("Color 1"))
                .frame(height: 100)
                .padding(12)
                .background(Color("InputField"))
                .clipShape(RoundedRectangle(cornerRadius: 35))
                .scrollContentBackground(.hidden)
            if notes.isEmpty {
                Text("Description, reminders, tips...")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Color("Color 1").opacity(0.6))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
            }
        }
    }
    
    // MARK: - Color Picker
    private var colorPicker: some View {
        HStack(spacing: 16) {
            ForEach(Array(availableColors.prefix(4).enumerated()), id: \.offset) { _, color in
                Button {
                    selectedColor = color
                } label: {
                    Circle()
                        .fill(Color(hex: color))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle().strokeBorder(
                                Color(hex: selectedColor == color ? "#403029" : "clear"),
                                lineWidth: selectedColor == color ? 3 : 0
                            )
                        )
                }
                .accessibilityLabel("Select color")
                .accessibilityAddTraits(selectedColor == color ? .isSelected : [])
            }
            
            ColorPicker("", selection: Binding(
                get: { Color(hex: selectedColor) },
                set: { newColor in selectedColor = newColor.toHex() }
            ), supportsOpacity: false)
            .labelsHidden()
            .frame(width: 50, height: 50)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    // MARK: - Bottom Buttons
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // Save Button
            Button {
                updateActivity()
            } label: {
                Text("Save Changes")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .dynamicTypeSize(.medium ... .accessibility1)
                    .foregroundStyle(Color("jsavebutton"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isValidActivity ? Color("AddButton") : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 100))
            }
            .disabled(!isValidActivity)
            
            // Delete Button — muted red, not bright
            Button(role: .destructive) {
                deleteActivity()
            } label: {
                Text("Delete Activity")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .dynamicTypeSize(.medium ... .accessibility1)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(softRed)
                    .clipShape(RoundedRectangle(cornerRadius: 100))
            }
            
            // Cancel Button
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 17, design: .rounded))
                    .dynamicTypeSize(.medium ... .accessibility1)
                    .foregroundStyle(Color("jcancel"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("CancelButton"))
                    .clipShape(RoundedRectangle(cornerRadius: 100))
            }
        }
        .padding(20)
        .background(Color("Background"))
    }
    
    // MARK: - Methods
    private func updateActivity() {
        guard let viewModel = viewModel else { dismiss(); return }
        viewModel.updateActivity(
            activity,
            name: activityName,
            time: selectedTime,
            color: selectedColor,
            placeName: placeName.isEmpty ? nil : placeName,
            notes: notes.isEmpty ? nil : notes,
            mapLink: mapLink.isEmpty ? nil : mapLink
        )
        dismiss()
    }
    
    private func deleteActivity() {
        guard let viewModel = viewModel else { dismiss(); return }
        viewModel.deleteActivity(activity)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    let activity = Activity(
        name: "Oxford Street",
        time: Date(),
        color: "#7E5E5E",
        notes: "Don't forget wallet"
    )
    return EditActivitySheet(activity: activity, viewModel: nil)
}
