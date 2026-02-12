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
        
        print("🔵 START createTrip")
        print("🔵 Trip name: \(name)")
        print("🔵 Start date: \(startDate)")
        print("🔵 End date: \(endDate)")
        print("🔵 Color theme: \(colorTheme)")
        
        // Safety check: Ensure dates are valid
        guard startDate <= endDate else {
            print("❌ Invalid dates: start (\(startDate)) is after end (\(endDate))")
            let fixedEndDate = startDate
            return createTrip(name: name, startDate: startDate, endDate: fixedEndDate, colorTheme: colorTheme)
        }
        
        let trip = Trip(
            name: name,
            startDate: startDate,
            endDate: endDate,
            colorTheme: colorTheme
        )
        
        print("🔵 Created trip object: \(trip.name)")
        
        // Generate days (up to 14 days)
        let days = generateDays(from: startDate, to: endDate)
        trip.days = days
        for day in days {
            day.trip = trip
        }
        
        print("🔵 Generated \(days.count) days")
        
        modelContext.insert(trip)
        print("🔵 Inserted trip into context")
        
        // ✅ DEBUG: Try to save immediately
        do {
            try modelContext.save()
            print("✅ SAVED SUCCESSFULLY TO DATABASE")
        } catch {
            print("❌ SAVE FAILED: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
        
        // ✅ DEBUG: Fetch immediately after save
        do {
            let descriptor = FetchDescriptor<Trip>()
            let allTrips = try modelContext.fetch(descriptor)
            print("🔍 TRIPS IN DATABASE RIGHT AFTER SAVE: \(allTrips.count)")
            for t in allTrips {
                print("  - Trip: \(t.name), Color: \(t.colorTheme), Days: \(t.days.count)")
            }
        } catch {
            print("❌ IMMEDIATE FETCH FAILED: \(error)")
        }
        
        // Now call the normal save and fetch
        saveChanges()
        fetchTrips()
        
        print("🔵 Final trips array count: \(trips.count)")
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
            print("✅ Changes saved successfully")
            print("📊 Total trips in context: \(trips.count)")
        } catch {
            errorMessage = "Failed to save"
            print("❌ ERROR SAVING TO DATABASE:")
            print("❌ Error: \(error)")
            print("❌ Error description: \(error.localizedDescription)")
        }
    }
}
