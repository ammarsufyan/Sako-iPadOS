import SwiftUI
import SwiftData
import TipKit

@main
struct SakoApp: App {
    // Initialize WidgetDataManager when the app starts
    init() {
        // Initialize WidgetDataManager
        _ = WidgetDataManager.shared
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Products.self,
            ProductsOnSales.self,
            Sales.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            DestinationTabs()
        }
        .modelContainer(sharedModelContainer)
    }
}
