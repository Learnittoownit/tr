import SwiftUI

struct ExtendTripSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let currentStartDate: Date
    let currentEndDate: Date
    var onConfirm: (Date) -> Void

    @State private var selectedEndDate: Date

    private let brown = Color(hex: "#3A2F27")
    private let green = Color(hex: "#4A5D4E")
    private let cream = Color(hex: "#FAF4EC")

    init(currentStartDate: Date, currentEndDate: Date, onConfirm: @escaping (Date) -> Void) {
        self.currentStartDate = currentStartDate
        self.currentEndDate   = currentEndDate
        self.onConfirm        = onConfirm
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentEndDate) ?? currentEndDate
        self._selectedEndDate = State(initialValue: nextDay)
    }

    private var newDaysCount: Int {
        max(0, Calendar.current.dateComponents([.day], from: currentEndDate, to: selectedEndDate).day ?? 0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Info Card ─────────────────────────────────────────
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Trip starts")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(brown.opacity(0.55))
                                Text(formatDate(currentStartDate))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(brown)
                            }
                            Spacer()
                            Circle()
                                .fill(brown.opacity(0.15))
                                .frame(width: 6, height: 6)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Currently ends")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(brown.opacity(0.55))
                                Text(formatDate(currentEndDate))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(brown)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color("Card"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // "Adding X days" pill
                        if newDaysCount > 0 {
                            Text("+ \(newDaysCount) day\(newDaysCount == 1 ? "" : "s") will be added")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(green)
                                .clipShape(Capsule())
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .animation(.spring(response: 0.4), value: newDaysCount)

                    // ── Calendar Picker ───────────────────────────────────
                    let minDate = Calendar.current.date(byAdding: .day, value: 1, to: currentEndDate) ?? currentEndDate

                    DatePicker(
                        "New end date",
                        selection: $selectedEndDate,
                        in: minDate...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(green)
                    .padding(.horizontal, 8)

                    Spacer()

                    // ── Confirm Button ────────────────────────────────────
                    Button {
                        onConfirm(selectedEndDate)
                        dismiss()
                    } label: {
                        Text(newDaysCount > 0
                             ? "Add \(newDaysCount) Day\(newDaysCount == 1 ? "" : "s")"
                             : "Select a date above")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(newDaysCount > 0 ? cream : brown.opacity(0.35))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(newDaysCount > 0 ? brown : Color("Card"))
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                    .disabled(newDaysCount == 0)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Extend Trip")
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
