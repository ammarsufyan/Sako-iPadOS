import Foundation
import SwiftData
import WidgetKit

// Model untuk berbagi data dengan widget
struct MonthlyRevenue: Codable {
    let amount: Int
    let growth: Double
    let date: Date
    let previousAmount: Int
}

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let appGroupIdentifier = "group.ammarsufyan.Sako.sharedData"
    private let revenueKey = "monthlyRevenue"
    
    private init() {
        // Akan diperbarui ketika RecapView muncul
    }
    
    // Fungsi untuk memperbarui data widget dengan pendapatan bulanan terbaru
    func updateMonthlyRevenue(amount: Int, previousAmount: Int, date: Date) {
        // Hitung persentase pertumbuhan
        let growth: Double
        if previousAmount > 0 {
            growth = Double(amount - previousAmount) / Double(previousAmount) * 100
        } else {
            growth = 0
        }
        
        let revenue = MonthlyRevenue(
            amount: amount, 
            growth: growth, 
            date: date,
            previousAmount: previousAmount
        )
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(revenue)
            
            guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
                return
            }
            
            sharedDefaults.set(data, forKey: revenueKey)
            sharedDefaults.synchronize()
            
            // Refresh widget
            #if os(iOS)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        } catch {
            // Handle error silently
        }
    }
}

// Extension untuk dipanggil dari RecapView
extension WidgetDataManager {
    func updateWidgetWithRecapData(totalRevenue: Int, previousMonthRevenue: Int, date: Date) {
        // Perbarui data widget
        updateMonthlyRevenue(
            amount: totalRevenue, 
            previousAmount: previousMonthRevenue, 
            date: date
        )
    }
    
    // Fungsi untuk mendapatkan data pendapatan berdasarkan tanggal (bulan) tertentu
    func getRevenueForMonth(sales: [Sales], date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        
        let filteredSales = sales.filter { sale in
            let saleComponents = calendar.dateComponents([.year, .month], from: sale.date)
            return saleComponents.year == components.year && saleComponents.month == components.month
        }
        
        return filteredSales.reduce(0) { $0 + $1.totalPrice }
    }
    
    // Fungsi untuk mendapatkan data pendapatan bulan sebelumnya
    func getPreviousMonthRevenue(sales: [Sales], currentDate: Date) -> Int {
        let calendar = Calendar.current
        guard let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: currentDate) else {
            return 0
        }
        
        return getRevenueForMonth(sales: sales, date: previousMonthDate)
    }
} 