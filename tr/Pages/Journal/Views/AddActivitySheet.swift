import SwiftUI
import SwiftData

struct AddActivitySheet: View {
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    let day: Day
    let viewModel: TripDetailViewModel?
    
    // MARK: - State
    @State private var activityName = ""
    @State private var selectedTime = Date()
    @State private var placeName = ""
    @State private var notes = ""
    @State private var mapLink = ""
    @State private var menuLink = ""
    @State private var bookingLink = ""
    @State private var selectedColor = "#E0C48A" // Default golden
//    @State private var showingColorPicker = false
    
    // MARK: - Scaled Metrics
    @ScaledMetric private var inputPadding: CGFloat = 16
    @ScaledMetric private var sectionSpacing: CGFloat = 16
    
    // MARK: - Available Colors
    private let availableColors = ["#E0C48A", "#9FAE8F", "#E6B3A2", "#9EC7C0", "#B9B2D8"]
    
    // MARK: - Computed Properties
    private var isValidActivity: Bool {
        !activityName.isEmpty
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content - centered vertically
                ScrollView {
                    VStack(spacing: sectionSpacing) {
                        // Activity Name
                        inputField(
                            placeholder: "Name of Place...",
                            text: $activityName
                        )
                        
                        // Time Picker
                        timePicker
                        
                        // Links Section
                        linksSection
                        
                        // Notes
                        notesField
                        
                        // Color Picker
                        colorPicker
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 80)
                    .padding(.bottom, 200)
                }
                
                // Bottom Buttons - Fixed at bottom
                bottomButtons
            }
        }
//        .sheet(isPresented: $showingColorPicker) {
//            CustomColorPickerSheet(selectedColor: $selectedColor)
//        }
    }
    
    // MARK: - Input Field (custom placeholder)
    private func inputField(placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(Color("Color 1").opacity(0.6)) // custom placeholder color
                    .padding(.horizontal, 20)
            }
            
            TextField("", text: text)
                .font(.system(size: 16, design: .rounded))
                .dynamicTypeSize(.medium ... .accessibility2)
                .foregroundStyle(Color("Color 1")) // Match description text color
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
                .foregroundStyle(Color("Color 1")) // Match description text color
            
            Spacer()
            
            DatePicker(
                "",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .tint(Color("Color 1")) // Controls picker tint
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color("InputField"))
        .clipShape(RoundedRectangle(cornerRadius: 35))
    }
    
    // MARK: - Links Section (custom placeholder)
    private var linksSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .leading) {
                if mapLink.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(Color("Color 1").opacity(0.6))
                            .accessibilityHidden(true)
                        Text("Map, Menu, Booking...")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(Color("Color 1").opacity(0.6))
                    }
                    .padding(.horizontal, 20)
                }
                
                HStack {
                    Image(systemName: "link")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(Color("Color 1"))
                        .accessibilityHidden(true)
                    
                    TextField("", text: $mapLink)
                        .font(.system(size: 16, design: .rounded))
                        .dynamicTypeSize(.medium ... .accessibility1)
                        .foregroundStyle(Color("Color 1")) // Match description text color
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .background(Color("InputField"))
            .clipShape(RoundedRectangle(cornerRadius: 35))
        }
    }
    
    // MARK: - Notes Field
    private var notesField: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $notes)
                .font(.system(size: 15, design: .rounded))
                .dynamicTypeSize(.small ... .accessibility2)
                .foregroundStyle(Color("Color 1")) // Description text color
                .frame(height: 100)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color("InputField"))
                .clipShape(RoundedRectangle(cornerRadius: 35))
                .scrollContentBackground(.hidden)
            
            if notes.isEmpty {
                Text("Description, reminders, tips...")
                    .font(.system(size: 15, design: .rounded))
                    .dynamicTypeSize(.small ... .accessibility1)
                    .foregroundStyle(Color("Color 1").opacity(0.6)) // subtle placeholder
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
            }
        }
    }
    
    // MARK: - Color Picker
    private var colorPicker: some View {
        HStack(spacing: 16) {
            // First 4 static colors
            ForEach(Array(availableColors.prefix(4).enumerated()), id: \.offset) { index, color in
                Button {
                    selectedColor = color
                } label: {
                    Circle()
                        .fill(Color(hex: color))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    Color(hex: selectedColor == color ? "#403029" : "clear"),
                                    lineWidth: selectedColor == color ? 3 : 0
                                )
                        )
                }
                .accessibilityLabel("Select color")
                .accessibilityAddTraits(selectedColor == color ? .isSelected : [])
            }
            
            // Native iOS Color Picker (same size as circles)
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
            // Add Button
            Button {
                addActivity()
            } label: {
                Text("Add to Day \(day.dayNumber)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .dynamicTypeSize(.medium ... .accessibility1)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isValidActivity ? Color("AddButton") : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 100))
            }
            .disabled(!isValidActivity)
            
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
    private func addActivity() {
        guard let viewModel = viewModel else {
            print("❌ ViewModel is nil!")
            dismiss()
            return
        }
        
        viewModel.addActivity(
            to: day,
            name: activityName,
            time: selectedTime,
            color: selectedColor,
            placeName: placeName.isEmpty ? nil : placeName,
            notes: notes.isEmpty ? nil : notes,
            mapLink: mapLink.isEmpty ? nil : mapLink,
            menuLink: nil,
            bookingLink: nil
        )
        dismiss()
    }
}

// MARK: - Custom Color Picker Sheet
struct CustomColorPickerSheet: View {
    @Binding var selectedColor: String
    @State private var tempColor: Color
    
    init(selectedColor: Binding<String>) {
        self._selectedColor = selectedColor
        self._tempColor = State(initialValue: Color(hex: selectedColor.wrappedValue))
    }
    
    var body: some View {
        ColorPicker("", selection: $tempColor, supportsOpacity: false)
            .labelsHidden()
            .onChange(of: tempColor) { _, newColor in
                selectedColor = newColor.toHex()
            }
    }
}

// MARK: - Color to Hex Extension
extension Color {
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}

// MARK: - Preview
#Preview {
    AddActivitySheet(
        day: Day(date: Date(), dayNumber: 2),
        viewModel: nil
    )
}
