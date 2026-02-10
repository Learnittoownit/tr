import Foundation
import SwiftData

@Model
final class Day {
    var id: UUID
    var date: Date
    var dayNumber: Int
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Activity.day)
    var activities: [Activity] = []
    
    var trip: Trip?
    
    init(date: Date, dayNumber: Int) {
        self.id = UUID()
        self.date = date
        self.dayNumber = dayNumber
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
    
    var sortedActivities: [Activity] {
        activities.sorted { $0.time < $1.time }
    }
}
