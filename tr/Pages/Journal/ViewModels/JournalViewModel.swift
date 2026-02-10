import Foundation
import SwiftData
import Observation

@Observable
final class JournalViewModel {
    
    // MARK: - Properties
    private let modelContext: ModelContext
    
    var trips: [Trip] = []
    var searchQuery: String = ""
    var errorMessage: String?
    
    // MARK: - Computed Properties
    var filteredTrips: [Trip] {
        if searchQuery.isEmpty {
            return trips
        }
        
        let query = searchQuery.lowercased()
        
        // Separate trips into two groups
        let startsWithQuery = trips.filter { trip in
            trip.name.lowercased().hasPrefix(query)
        }
        
        let containsQuery = trips.filter { trip in
            let lowercasedName = trip.name.lowercased()
            return lowercasedName.contains(query) && !lowercasedName.hasPrefix(query)
        }
        
        // Return trips that start with query first, then trips that contain it
        return startsWithQuery + containsQuery
    }
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTrips()
    }
    
    // MARK: - Methods
    
    /// Fetch all trips from database
    func fetchTrips() {
        do {
            let descriptor = FetchDescriptor<Trip>(
                sortBy: [SortDescriptor(\.startDate, order: .reverse)]
            )
            trips = try modelContext.fetch(descriptor)
            print("✅ Loaded \(trips.count) trips")
        } catch {
            errorMessage = "Failed to load trips"
            print("❌ Error fetching trips: \(error)")
        }
    }
    
    /// Create a new trip
    func createTrip(
        name: String,
        startDate: Date,
        endDate: Date,
        colorTheme: String
    ) -> Trip {
        
        // Safety check: Ensure dates are valid
        guard startDate <= endDate else {
            print("❌ Invalid dates: start (\(startDate)) is after end (\(endDate))")
            // Fix the dates automatically
            let fixedEndDate = startDate
            return createTrip(name: name, startDate: startDate, endDate: fixedEndDate, colorTheme: colorTheme)
        }
        
        let trip = Trip(
            name: name,
            startDate: startDate,
            endDate: endDate,
            colorTheme: colorTheme
        )
        
        // Generate days (up to 14 days)
        let days = generateDays(from: startDate, to: endDate)
        trip.days = days
        for day in days {
            day.trip = trip
        }
        
        modelContext.insert(trip)
        saveChanges()
        fetchTrips()
        
        print("✅ Created trip: \(name)")
        return trip
    }
    
    /// Delete a trip
    func deleteTrip(_ trip: Trip) {
        modelContext.delete(trip)
        saveChanges()
        fetchTrips()
        print("✅ Deleted trip: \(trip.name)")
    }
    
    // MARK: - Private Helpers
    
    /// Generate days for date range (max 14 days)
    private func generateDays(from startDate: Date, to endDate: Date) -> [Day] {
        var days: [Day] = []
        var currentDate = startDate
        var dayNumber = 1
        
        // Safety: Ensure we don't create infinite loop
        let maxDays = 14
        
        while currentDate <= endDate && dayNumber <= maxDays {
            let day = Day(date: currentDate, dayNumber: dayNumber)
            days.append(day)
            
            guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
            dayNumber += 1
        }
        
        return days
    }
    
    /// Save changes to database
    private func saveChanges() {
        do {
            try modelContext.save()
            print("✅ Changes saved")
        } catch {
            errorMessage = "Failed to save"
            print("❌ Error saving: \(error)")
        }
    }
}
