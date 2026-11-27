import WidgetKit
import SwiftUI

// Simple model for demonstration. In a real app, replace with your shared data source.
//struct Person: Identifiable {
//    let id = UUID()
//    let name: String
//    let birthday: Date
//}

// Helper to build a fixed mock list
//fileprivate extension Array where Element == Person {
//    static var mockPeople: [Person] {
//        var comps = DateComponents(calendar: Calendar.current)
//        func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
//            comps.year = year
//            comps.month = month
//            comps.day = day
//            return comps.date ?? Date()
//        }
//        return [
//            Person(name: "Alice", birthday: date(1990, 11, 3)),
//            Person(name: "Bob", birthday: date(1985, 7, 22)),
//            Person(name: "Charlie", birthday: date(2001, 11, 18)),
//            Person(name: "Diana", birthday: date(1993, 12, 9)),
//            Person(name: "Eve", birthday: date(1988, 11, 30))
//        ]
//    }
//}

var persons: [Person] = []

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), novemberBirthdays: ["Alice", "Charlie", "Eve"])
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let names = Self.novemberBirthdayNames(from: persons)
        return SimpleEntry(date: Date(), configuration: configuration, novemberBirthdays: names)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Filter people born in November and keep the same names for each entry in this simple example.
        let names = Self.novemberBirthdayNames(from: persons)

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration, novemberBirthdays: names)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    private static func novemberBirthdayNames(from people: [Person]) -> [String] {
        let cal = Calendar.current
        
        let month = Calendar.current.component(.month, from: Date())
        
        return people.filter { cal.component(.month, from: $0.dateOfBirth) == month }
            .map { $0.firstName }
            .sorted()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let novemberBirthdays: [String]
}

struct PerDataWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            let month = Calendar.current.component(.month, from: Date())
            Text("Born in the \(month).th month this year...")
                .font(.headline)
            if entry.novemberBirthdays.isEmpty {
                Text("No birthdays")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                // Show up to 4 names to fit in small widgets
                ForEach(entry.novemberBirthdays.prefix(4), id: \.self) { name in
                    Text("• \(name)")
                        .font(.footnote)
                }
                if entry.novemberBirthdays.count > 4 {
                    Text("+\(entry.novemberBirthdays.count - 4) more")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        
        .task {
            let predicate = NSPredicate(format: "birthdayDate.month == 11")
            persons = await getAllPersons( predicate: predicate)
        }
        
        
    }
        
}

struct PerDataWidget: Widget {
    let kind: String = "PerDataWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            PerDataWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Birthdays in November")
        .description("Shows people who have birthdays in November.")
        // You can add .supportedFamilies if you want to customize per size.
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    PerDataWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley, novemberBirthdays: ["Alice", "Charlie"]) 
    SimpleEntry(date: .now, configuration: .starEyes, novemberBirthdays: ["Alice", "Charlie", "Eve"]) 
}
