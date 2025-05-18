//
//  SakoWidget.swift
//  SakoWidget
//
//  Created by Ammar Sufyan on 18/05/25.
//

import WidgetKit
import SwiftUI
import SwiftData

// Model untuk digunakan dalam widget
struct MonthlyRevenue: Codable {
    let amount: Int
    let growth: Double
    let date: Date
    let previousAmount: Int
    let isLatestMonth: Bool
    
    // Untuk backward compatibility
    enum CodingKeys: String, CodingKey {
        case amount, growth, date, previousAmount, isLatestMonth
    }
    
    init(amount: Int, growth: Double, date: Date, previousAmount: Int = 0, isLatestMonth: Bool = false) {
        self.amount = amount
        self.growth = growth
        self.date = date
        self.previousAmount = previousAmount
        self.isLatestMonth = isLatestMonth
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        amount = try container.decode(Int.self, forKey: .amount)
        growth = try container.decode(Double.self, forKey: .growth)
        date = try container.decode(Date.self, forKey: .date)
        // Handle optional previousAmount for backward compatibility
        previousAmount = try container.decodeIfPresent(Int.self, forKey: .previousAmount) ?? 0
        // Handle optional isLatestMonth for backward compatibility
        isLatestMonth = try container.decodeIfPresent(Bool.self, forKey: .isLatestMonth) ?? false
    }
}

struct Provider: AppIntentTimelineProvider {
    // App group identifier
    private let appGroupIdentifier = "group.ammarsufyan.Sako.sharedData"
    private let revenueKey = "monthlyRevenue"
    private let currentMonthKey = "currentMonthRevenue"
    
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
        
        // Update the widget every 5 seconds (for testing)
        let nextUpdate = Calendar.current.date(byAdding: .second, value: 5, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    // Function to get revenue data from UserDefaults with fallback
    func getRevenueData() -> MonthlyRevenue {
        // Prioritas 1: Ambil data bulan saat ini
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
           let data = sharedDefaults.data(forKey: currentMonthKey) {
            do {
                let decoder = JSONDecoder()
                let revenue = try decoder.decode(MonthlyRevenue.self, from: data)
                return revenue
            } catch {
                // Fallback ke prioritas berikutnya jika decode gagal
            }
        }
        
        // Prioritas 2: Ambil data normal dan filter hanya tampilkan yg isLatestMonth = true
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
           let data = sharedDefaults.data(forKey: revenueKey) {
            do {
                let decoder = JSONDecoder()
                let revenue = try decoder.decode(MonthlyRevenue.self, from: data)
                if revenue.isLatestMonth {
                    return revenue
                }
            } catch {
                // Fallback ke data default
            }
        }
        
        // Return data default jika tidak ada data atau bukan bulan terbaru
        return MonthlyRevenue(
            amount: 2500000, 
            growth: 0.0, 
            date: Date(), 
            previousAmount: 2500000,
            isLatestMonth: true
        )
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
    
    var formattedPreviousAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        
        let number = NSNumber(value: entry.revenue.previousAmount)
        return formatter.string(from: number) ?? "\(entry.revenue.previousAmount)"
    }
    
    var growthAmount: Int {
        return abs(entry.revenue.amount - entry.revenue.previousAmount)
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

            // Percentage with arrow - show growth compared to previous month
            HStack(spacing: 4) {
                Image(systemName: entry.revenue.growth >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 12))
                    .foregroundColor(entry.revenue.growth >= 0 ? .green : .red)
                
                Text("Rp\(formattedGrowthAmount)(\(entry.revenue.growth >= 0 ? "+" : "-")\(formattedGrowth)%)")
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
