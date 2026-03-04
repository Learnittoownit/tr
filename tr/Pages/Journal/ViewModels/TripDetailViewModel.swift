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
    func toggleDay(at index: Int) {
        selectedDayIndex = selectedDayIndex == index ? nil : index
    }
    
    func isDayExpanded(at index: Int) -> Bool {
        selectedDayIndex == index
    }
    
    // MARK: - Task 9: Delete Day
    func deleteDay(_ day: Day) {
        trip.days.removeAll { $0.id == day.id }
        
        let sorted = trip.days.sorted { $0.dayNumber < $1.dayNumber }
        for (index, d) in sorted.enumerated() {
            d.dayNumber = index + 1
            d.date = Calendar.current.date(byAdding: .day, value: index, to: trip.startDate) ?? d.date
        }
        
        trip.endDate     = sorted.last?.date ?? trip.startDate
        selectedDayIndex = nil
        trip.updatedAt   = Date()
        modelContext.delete(day)
        saveChanges()
        print("✅ Deleted day. Remaining: \(trip.days.count)")
    }
    
    // MARK: - Task 9: Extend Trip
    func extendTrip(to newEndDate: Date) {
        let calendar   = Calendar.current
        let currentEnd = calendar.startOfDay(for: trip.endDate)
        let targetEnd  = calendar.startOfDay(for: newEndDate)
        guard targetEnd > currentEnd else { return }
        
        var date      = calendar.date(byAdding: .day, value: 1, to: currentEnd)!
        var dayNumber = (trip.days.map { $0.dayNumber }.max() ?? 0) + 1
        
        while date <= targetEnd {
            let newDay  = Day(date: date, dayNumber: dayNumber)
            newDay.trip = trip
            trip.days.append(newDay)
            modelContext.insert(newDay)
            date      = calendar.date(byAdding: .day, value: 1, to: date)!
            dayNumber += 1
        }
        
        trip.endDate   = targetEnd
        trip.updatedAt = Date()
        saveChanges()
        print("✅ Extended to \(targetEnd). Total days: \(trip.days.count)")
    }
    
    // MARK: - Activity Methods
    func addActivity(
        to day: Day, name: String, time: Date,
        color: String = "#403029", placeName: String? = nil,
        notes: String? = nil, mapLink: String? = nil,
        menuLink: String? = nil, bookingLink: String? = nil
    ) {
        let activity = Activity(name: name, time: time, color: color, placeName: placeName, notes: notes)
        activity.mapLink     = mapLink
        activity.menuLink    = menuLink
        activity.bookingLink = bookingLink
        activity.day         = day
        day.activities.append(activity)
        day.updatedAt  = Date()
        trip.updatedAt = Date()
        modelContext.insert(activity)
        saveChanges()
        print("✅ Added activity: \(name) to Day \(day.dayNumber)")
    }
    
    func updateActivity(
        _ activity: Activity, name: String? = nil, time: Date? = nil,
        color: String? = nil, placeName: String? = nil, notes: String? = nil,
        mapLink: String? = nil, menuLink: String? = nil, bookingLink: String? = nil
    ) {
        if let name        = name        { activity.name        = name }
        if let time        = time        { activity.time        = time }
        if let color       = color       { activity.color       = color }
        if let placeName   = placeName   { activity.placeName   = placeName }
        if let notes       = notes       { activity.notes       = notes }
        if let mapLink     = mapLink     { activity.mapLink     = mapLink }
        if let menuLink    = menuLink    { activity.menuLink    = menuLink }
        if let bookingLink = bookingLink { activity.bookingLink = bookingLink }
        activity.updatedAt      = Date()
        activity.day?.updatedAt = Date()
        trip.updatedAt          = Date()
        saveChanges()
        print("✅ Updated activity: \(activity.name)")
    }
    
    func deleteActivity(_ activity: Activity) {
        activity.day?.activities.removeAll { $0.id == activity.id }
        activity.day?.updatedAt = Date()
        trip.updatedAt          = Date()
        modelContext.delete(activity)
        saveChanges()
        print("✅ Deleted activity: \(activity.name)")
    }
    
    func getDay(byNumber number: Int) -> Day? {
        trip.days.first { $0.dayNumber == number }
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save"
            print("❌ Error saving: \(error)")
        }
    }
}
