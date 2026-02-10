import Foundation
import SwiftData

@Model
final class Activity {
    var id: UUID
    var name: String
    var time: Date
    var color: String // Activity color for card styling
    var placeName: String?
    var notes: String?
    var mapLink: String?
    var menuLink: String?
    var bookingLink: String?
    var createdAt: Date
    var updatedAt: Date
    
    var day: Day?
    
    init(
        name: String,
        time: Date,
        color: String = "#E0C48A", // Default to dark brown
        placeName: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.time = time
        self.color = color
        self.placeName = placeName
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: time)
    }
    
    var hasLinks: Bool {
        mapLink != nil || menuLink != nil || bookingLink != nil
    }
}
