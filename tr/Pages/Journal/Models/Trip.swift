import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var name: String              // Only trip name now
    var startDate: Date
    var endDate: Date
    var colorTheme: String
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Day.trip)
    var days: [Day] = []
    
    init(
        name: String,
        startDate: Date,
        endDate: Date,
        colorTheme: String
    ) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.colorTheme = colorTheme
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var activityCount: Int {
        days.reduce(0) { $0 + $1.activities.count }
    }
    
    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: startDate)
        
        formatter.dateFormat = "d, yyyy"
        let end = formatter.string(from: endDate)
        
        return "\(start) - \(end)"
    }
    
    // Available color themes
    static let availableThemes: [String] = [
        "#FFB5A0",  // Soft Coral
        "#B8C5A0",  // Sage Green
        "#FFB6C1",  // Rose
        "#D4C5F9",  // Lavender
        "#B5EAD7",  // Mint
        "#A0C4E8",  // Sky Blue
        "#EFC987",  // Mustard (fixed typo from F0C987)
        "#E2725B"   // Terracotta
    ]
}
