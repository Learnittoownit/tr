import SwiftUI
import SwiftData

#if os(iOS)
import UIKit
#endif

struct JournalView: View {
    
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Routing back to MainPage
    var onBack: (() -> Void)? = nil
    
    // MARK: - State
    @State private var viewModel: JournalViewModel?
    @State private var searchText = ""
    @State private var showingCreateTrip = false
    @State private var isSelecting = false
    @State private var selectedTrips: Set<PersistentIdentifier> = []
    @State private var showDeleteConfirmation = false

    // Task 7: holds the newly created trip to trigger navigation
    @State private var createdTrip: Trip? = nil

    // MARK: - Scaled Metrics
    @ScaledMetric private var cardPadding: CGFloat = 16
    @ScaledMetric private var spacing: CGFloat = 16
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if let viewModel = viewModel {
                        if viewModel.filteredTrips.isEmpty {
                            emptyState
                        } else {
                            tripsList(trips: viewModel.filteredTrips)
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    glassySearchBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
            .navigationTitle("Trips")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelecting {
                        Button("Cancel") {
                            isSelecting = false
                            selectedTrips.removeAll()
                        }
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color(hex: "#3A2F27"))
                    } else {
                        Button {
                            if let onBack { onBack() } else { dismiss() }
                        } label: {
                            Text("Back")
                                .font(.system(size: 17, design: .rounded))
                                .foregroundStyle(colorScheme == .dark ? Color.white : Color(hex: "#3A2F27"))
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSelecting {
                        Button {
                            if !selectedTrips.isEmpty { showDeleteConfirmation = true }
                        } label: {
                            Text("Delete (\(selectedTrips.count))")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(selectedTrips.isEmpty ? .gray : .red)
                        }
                        .disabled(selectedTrips.isEmpty)
                    } else {
                        Button("Select") { isSelecting = true }
                            .font(.system(size: 17, design: .rounded))
                            .foregroundStyle(colorScheme == .dark ? Color.white : Color(hex: "#3A2F27"))
                    }
                }
            }
            .confirmationDialog(
                "Delete \(selectedTrips.count) trip\(selectedTrips.count == 1 ? "" : "s")?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let vm = viewModel {
                        for id in selectedTrips {
                            if let trip = vm.trips.first(where: { $0.persistentModelID == id }) {
                                vm.deleteTrip(trip)
                            }
                        }
                    }
                    selectedTrips.removeAll()
                    isSelecting = false
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
            // Task 7: navigate to TripDetailView as soon as createdTrip is set
            .navigationDestination(item: $createdTrip) { trip in
                TripDetailView(trip: trip)
            }
            .sheet(isPresented: $showingCreateTrip) {
                if let viewModel = viewModel {
                    // Task 7: pass the callback — dismiss sheet then push TripDetailView
                    CreateTripSheet(viewModel: viewModel) { newTrip in
                        createdTrip = newTrip
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = JournalViewModel(modelContext: modelContext)
            }
            viewModel?.fetchTrips()
        }
        .onChange(of: showingCreateTrip) { _, isShowing in
            if !isShowing { viewModel?.fetchTrips() }
        }
        .onChange(of: searchText) { _, newValue in
            viewModel?.searchQuery = newValue
        }
    }
    
    // MARK: - Glassy Bottom Search Bar
    private var glassySearchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(colorScheme == .dark ? Color.white : .gray)
                    .font(.system(size: 18))
                
                TextField("Search", text: $searchText)
                    .font(.system(size: 17))
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color("jplus"))
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(colorScheme == .dark ? Color.white : Color("jplus"))
                            .font(.system(size: 18))
                    }
                } else {
                    Button { } label: {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(colorScheme == .dark ? Color.white : .gray)
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 28).fill(.ultraThinMaterial))
            
            Button {
                showingCreateTrip = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color(hex: "#3A2F27"))
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .accessibilityLabel("Create new trip")
        }
    }
    
    // MARK: - Share
    private func shareTrip(_ trip: Trip) {
        let shareText = "Trip: \(trip.name)\nDates: \(trip.dateRangeString)\nDuration: \(trip.duration) days\nActivities: \(trip.activityCount)"
        #if os(iOS)
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.keyWindow,
           let root = window.rootViewController {
            var presenter = root
            while let presented = presenter.presentedViewController { presenter = presented }
            presenter.present(activityVC, animated: true)
        }
        #else
        print(shareText)
        #endif
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "suitcase")
                .font(.system(size: 60, design: .rounded))
                .foregroundStyle(.gray.opacity(0.5))
                .accessibilityHidden(true)
            Text("No trips yet")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .dynamicTypeSize(.large ... .accessibility3)
                .foregroundStyle(.gray)
            Text("Tap + to create your first trip")
                .font(.system(size: 15, design: .rounded))
                .dynamicTypeSize(.medium ... .accessibility2)
                .foregroundStyle(.gray.opacity(0.7))
            Spacer()
        }
    }
    
    // MARK: - Trips List
    private func tripsList(trips: [Trip]) -> some View {
        ScrollView {
            VStack(spacing: spacing) {
                ForEach(trips) { trip in
                    let isSelected = selectedTrips.contains(trip.persistentModelID)
                    
                    HStack(spacing: 12) {
                        if isSelecting {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(isSelected ? Color("Green") : Color.gray.opacity(0.5))
                                .animation(.easeInOut(duration: 0.2), value: isSelected)
                        }
                        
                        Group {
                            if isSelecting {
                                TripCard(trip: trip)
                                    .onTapGesture {
                                        if isSelected {
                                            selectedTrips.remove(trip.persistentModelID)
                                        } else {
                                            selectedTrips.insert(trip.persistentModelID)
                                        }
                                    }
                            } else {
                                NavigationLink {
                                    TripDetailView(trip: trip)
                                } label: {
                                    TripCard(trip: trip)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button { shareTrip(trip) } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    Button(role: .destructive) {
                                        viewModel?.deleteTrip(trip)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .opacity(isSelecting && !isSelected ? 0.6 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
    }
}

// MARK: - Trip Card
struct TripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(trip.name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .dynamicTypeSize(.large ... .accessibility2)
                .foregroundStyle(Color(hex: "#3A2F27"))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Text(trip.dateRangeString)
                .font(.system(size: 15, design: .rounded))
                .dynamicTypeSize(.small ... .accessibility1)
                .foregroundStyle(Color(hex: "#5A4A3D"))
                .minimumScaleFactor(0.9)
            
            Text("\(trip.duration) days • \(trip.activityCount) activities")
                .font(.system(size: 14, design: .rounded))
                .dynamicTypeSize(.small ... .large)
                .foregroundStyle(Color(hex: "#7A6A5A"))
                .minimumScaleFactor(0.9)
        }
        .padding(24)
        .frame(height: 140)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: trip.colorTheme))
        .clipShape(RoundedRectangle(cornerRadius: 35))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trip.name), \(trip.dateRangeString), \(trip.duration) days, \(trip.activityCount) activities")
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Preview
#Preview {
    JournalView()
        .modelContainer(DatabaseConfig.createPreviewContainer())
}
