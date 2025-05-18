import Foundation
import SwiftData
import WidgetKit

// Model for sharing with widget
struct MonthlyRevenue: Codable {
    let amount: Int
    let growth: Double
    let date: Date
}

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let appGroupIdentifier = "group.ammarsufyan.Sako.sharedData"
    private let revenueKey = "monthlyRevenue"
    
    private init() {
        // Will be updated when RecapView appears
    }
    
    // Update the widget data with the latest monthly revenue
    func updateMonthlyRevenue(amount: Int, growth: Double, date: Date) {
        let revenue = MonthlyRevenue(amount: amount, growth: growth, date: date)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(revenue)
            
            guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
                return
            }
            
            sharedDefaults.set(data, forKey: revenueKey)
            sharedDefaults.synchronize()
            
            // Trigger widget refresh
            #if os(iOS)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        } catch {
            // Handle error silently
        }
    }
}

// Extension to call from RecapView
extension WidgetDataManager {
    func updateWidgetWithRecapData(totalRevenue: Int, previousMonthRevenue: Int, date: Date) {
        // Calculate growth percentage
        let growth: Double
        if previousMonthRevenue > 0 {
            growth = Double(totalRevenue - previousMonthRevenue) / Double(previousMonthRevenue) * 100
        } else {
            growth = 0
        }
        
        // Update widget data
        updateMonthlyRevenue(amount: totalRevenue, growth: growth, date: date)
    }
} 