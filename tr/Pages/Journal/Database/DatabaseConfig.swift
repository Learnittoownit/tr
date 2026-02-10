import Foundation
import SwiftData

struct DatabaseConfig {
    
    // MARK: - Production Container (Real App)
    static func createContainer() -> ModelContainer {
        let schema = Schema([
            Trip.self,
            Day.self,
            Activity.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            print("✅ Database created successfully!")
            return container
        } catch {
            fatalError("❌ Could not create database: \(error)")
        }
    }
    
    // MARK: - Preview Container (For Testing in Xcode)
    static func createPreviewContainer() -> ModelContainer {
        let schema = Schema([
            Trip.self,
            Day.self,
            Activity.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            // Add sample data for preview
            addSampleData(to: container)
            
            return container
        } catch {
            fatalError("❌ Could not create preview container: \(error)")
        }
    }
    
    // MARK: - Sample Data
    private static func addSampleData(to container: ModelContainer) {
        let context = container.mainContext
        
        // Create sample trip
        let trip = Trip(
            name: "Summer Vacation",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 3),
            colorTheme: "#F5DEB3"
        )
        
        // Create days
        let day1 = Day(date: trip.startDate, dayNumber: 1)
        let day2 = Day(date: trip.startDate.addingTimeInterval(86400), dayNumber: 2)
        
        // Create activities with colors
        let activity1 = Activity(
            name: "Morning Coffee",
            time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: day2.date)!,
            color: "#6B7982",
            notes: "Don't forget to check the menu"
        )
        
        let activity2 = Activity(
            name: "Lunch",
            time: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: day2.date)!,
            color: "#7E5E5E",
            notes: "Reservation confirmed"
        )
        
        // Connect everything
        day2.activities = [activity1, activity2]
        activity1.day = day2
        activity2.day = day2
        
        trip.days = [day1, day2]
        day1.trip = trip
        day2.trip = trip
        
        context.insert(trip)
        try? context.save()
        
        print("✅ Sample data added")
    }
}
