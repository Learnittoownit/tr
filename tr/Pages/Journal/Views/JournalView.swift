import SwiftUI
import SwiftData

#if os(iOS)
import UIKit
#endif

struct JournalView: View {
    
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    @State private var viewModel: JournalViewModel?
    @State private var searchText = ""
    @State private var showingCreateTrip = false
    
    // MARK: - Scaled Metrics
    @ScaledMetric private var cardPadding: CGFloat = 16
    @ScaledMetric private var spacing: CGFloat = 16
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color("Background")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Content
                    if let viewModel = viewModel {
                        if viewModel.filteredTrips.isEmpty {
                            emptyState
                        } else {
                            tripsList(trips: viewModel.filteredTrips)
                        }
                    }
                }
                
                // Bottom Glassy Search Bar
                VStack {
                    Spacer()
                    glassySearchBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // Navigate back to home
                    } label: {
                        Text("Back")
                            .font(.system(size: 17, design: .rounded))
                            .dynamicTypeSize(.large ... .xxxLarge)
                            .foregroundStyle(Color(hex: "#3A2F27"))
                    }
                }
            }
            .sheet(isPresented: $showingCreateTrip) {
                CreateTripSheet()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = JournalViewModel(modelContext: modelContext)
            }
            viewModel?.fetchTrips()
        }
        .onChange(of: showingCreateTrip) { _, isShowing in
            if !isShowing {
                viewModel?.fetchTrips()
            }
        }
        .onChange(of: searchText) { _, newValue in
            viewModel?.searchQuery = newValue
        }
    }
    
    // MARK: - Glassy Bottom Search Bar (iOS Style)
    private var glassySearchBar: some View {
        HStack(spacing: 12) {
            // Search Field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)
                    .font(.system(size: 18))
                
                TextField("Search", text: $searchText)
                    .font(.system(size: 17))
                    .foregroundStyle(Color(hex: "#3A2F27"))
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray.opacity(0.6))
                            .font(.system(size: 18))
                    }
                } else {
                    Button {
                        // Microphone action
                    } label: {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.gray)
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
            )
            
            // Create Button (Glass Effect)
            Button {
                showingCreateTrip = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(hex: "#3A2F27"))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
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
            while let presented = presenter.presentedViewController {
                presenter = presented
            }
            presenter.present(activityVC, animated: true, completion: nil)
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
    
    // MARK: - Trips List (Single Column)
    private func tripsList(trips: [Trip]) -> some View {
        ScrollView {
            VStack(spacing: spacing) {
                ForEach(trips) { trip in
                    NavigationLink {
                        TripDetailView(trip: trip)
                    } label: {
                        TripCard(trip: trip)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button {
                            shareTrip(trip)
                        } label: {
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
            // Trip Name
            Text(trip.name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .dynamicTypeSize(.large ... .accessibility2)
                .foregroundStyle(Color(hex: "#3A2F27"))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Dates
            Text(trip.dateRangeString)
                .font(.system(size: 15, design: .rounded))
                .dynamicTypeSize(.small ... .accessibility1)
                .foregroundStyle(Color(hex: "#5A4A3D"))
                .minimumScaleFactor(0.9)
            
            // Duration + Activities
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
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
#Preview {
    JournalView()
        .modelContainer(DatabaseConfig.createPreviewContainer())
}
