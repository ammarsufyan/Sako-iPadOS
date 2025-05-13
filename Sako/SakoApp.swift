import SwiftUI
import SwiftData
import TipKit

@main
struct SakoApp: App {
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
