import Foundation
import SwiftData
import Observation

@Observable
final class TripDetailViewModel {
    
    // MARK: - Properties
    private let modelContext: ModelContext
    
    var trip: Trip
    var selectedDayIndex: Int?
    var errorMessage: String?
    
    // MARK: - Computed Properties
    var sortedDays: [Day] {
        trip.days.sorted { $0.dayNumber < $1.dayNumber }
    }
    
    // MARK: - Initialization
    init(modelContext: ModelContext, trip: Trip) {
        self.modelContext = modelContext
        self.trip = trip
    }
    
    // MARK: - Day Methods
    
    /// Toggle day expansion
    func toggleDay(at index: Int) {
        if selectedDayIndex == index {
            selectedDayIndex = nil
        } else {
            selectedDayIndex = index
        }
    }
    
    /// Check if day is expanded
    func isDayExpanded(at index: Int) -> Bool {
        selectedDayIndex == index
    }
    
    // MARK: - Activity Methods
    
    /// Add activity to a day
    func addActivity(
        to day: Day,
        name: String,
        time: Date,
        color: String = "#403029",
        placeName: String? = nil,
        notes: String? = nil,
        mapLink: String? = nil,
        menuLink: String? = nil,
        bookingLink: String? = nil
    ) {
        let activity = Activity(
            name: name,
            time: time,
            color: color,
            placeName: placeName,
            notes: notes
        )
        
        activity.mapLink = mapLink
        activity.menuLink = menuLink
        activity.bookingLink = bookingLink
        activity.day = day
        
        day.activities.append(activity)
        day.updatedAt = Date()
        trip.updatedAt = Date()
        
        modelContext.insert(activity)
        saveChanges()
        
        print("✅ Added activity: \(name) to Day \(day.dayNumber)")
    }
    
    /// Update an activity
    func updateActivity(
        _ activity: Activity,
        name: String? = nil,
        time: Date? = nil,
        color: String? = nil,
        placeName: String? = nil,
        notes: String? = nil,
        mapLink: String? = nil,
        menuLink: String? = nil,
        bookingLink: String? = nil
    ) {
        if let name = name { activity.name = name }
        if let time = time { activity.time = time }
        if let color = color { activity.color = color }
        if let placeName = placeName { activity.placeName = placeName }
        if let notes = notes { activity.notes = notes }
        if let mapLink = mapLink { activity.mapLink = mapLink }
        if let menuLink = menuLink { activity.menuLink = menuLink }
        if let bookingLink = bookingLink { activity.bookingLink = bookingLink }
        
        activity.updatedAt = Date()
        activity.day?.updatedAt = Date()
        trip.updatedAt = Date()
        
        saveChanges()
        print("✅ Updated activity: \(activity.name)")
    }
    
    /// Delete an activity
    func deleteActivity(_ activity: Activity) {
        if let day = activity.day {
            day.activities.removeAll { $0.id == activity.id }
            day.updatedAt = Date()
        }
        
        trip.updatedAt = Date()
        modelContext.delete(activity)
        saveChanges()
        
        print("✅ Deleted activity: \(activity.name)")
    }
    
    // MARK: - Helper Methods
    
    /// Get day by number
    func getDay(byNumber number: Int) -> Day? {
        trip.days.first { $0.dayNumber == number }
    }
    
    /// Save changes
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
