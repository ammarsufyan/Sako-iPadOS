//
//  SakoWidget.swift
//  SakoWidget
//
//  Created by Ammar Sufyan on 18/05/25.
//

import WidgetKit
import SwiftUI
import SwiftData

// Use the same model as in the app
struct MonthlyRevenue: Codable {
    let amount: Int
    let growth: Double
    let date: Date
}

struct Provider: AppIntentTimelineProvider {
    // App group identifier
    private let appGroupIdentifier = "group.ammarsufyan.Sako.sharedData"
    private let revenueKey = "monthlyRevenue"
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            revenue: getRevenueData(),
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        return SimpleEntry(
            date: Date(),
            revenue: getRevenueData(),
            configuration: configuration
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let revenue = getRevenueData()
        
        let entry = SimpleEntry(
            date: Date(),
            revenue: revenue,
            configuration: configuration
        )
        
        // Update the widget every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .second, value: 5, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    // Function to get revenue data from UserDefaults with fallback
    func getRevenueData() -> MonthlyRevenue {
        // Try to get data from shared UserDefaults first
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
           let data = sharedDefaults.data(forKey: revenueKey) {
            do {
                let decoder = JSONDecoder()
                let revenue = try decoder.decode(MonthlyRevenue.self, from: data)
                return revenue
            } catch {
                // Fallback to default data
            }
        }
        
        // Return current data as fallback
        return MonthlyRevenue(amount: 2500000, growth: 0.0, date: Date())
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let revenue: MonthlyRevenue
    let configuration: ConfigurationAppIntent
}

struct SakoWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        
        let number = NSNumber(value: entry.revenue.amount)
        return formatter.string(from: number) ?? "\(entry.revenue.amount)"
    }
    
    var formattedGrowth: String {
        return String(format: "%.1f", abs(entry.revenue.growth))
    }
    
    var growthAmount: Int {
        return Int(abs(Double(entry.revenue.amount) * entry.revenue.growth / 100))
    }
    
    var formattedGrowthAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        
        let number = NSNumber(value: growthAmount)
        return formatter.string(from: number) ?? "\(growthAmount)"
    }
    
    var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "id_ID")
        let month = formatter.string(from: entry.revenue.date)
        // Capitalize the first letter
        return month.prefix(1).uppercased() + month.dropFirst()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Total Pendapatan label
            Text("Total Pendapatan")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            // Revenue
            Text("Rp\(formattedPrice)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            // Percentage with arrow
            HStack(spacing: 4) {
                Image(systemName: entry.revenue.growth >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 12))
                    .foregroundColor(entry.revenue.growth >= 0 ? .green : .red)
                
                Text("Rp\(formattedGrowthAmount)(+\(formattedGrowth)%)")
                    .font(.system(size: 12))
                    .foregroundColor(entry.revenue.growth >= 0 ? .green : .red)
            }
            
            Spacer()
            
            // Month and icon row at bottom
            HStack {
                Spacer()
                
                // Month at bottom right
                Text(formattedMonth)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            // Move icon to top right
            Image("WidgetIcon")
                .scaledToFit()
                .frame(width: 28, height: 28)
                .padding(16),
            alignment: .topTrailing
        )
    }
}

struct SakoWidget: Widget {
    let kind: String = "SakoWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SakoWidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .supportedFamilies([.systemMedium]) // Only use medium size
        .configurationDisplayName("Sako Revenue")
        .description("Shows your monthly revenue data")
    }
}

#Preview(as: .systemMedium) {
    SakoWidget()
} timeline: {
    SimpleEntry(
        date: .now, 
        revenue: MonthlyRevenue(amount: 100000000, growth: 46.5, date: Date()),
        configuration: ConfigurationAppIntent()
    )
}
