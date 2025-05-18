import Foundation
import SwiftData
import WidgetKit

// Model untuk berbagi data dengan widget
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
}

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let appGroupIdentifier = "group.ammarsufyan.Sako.sharedData"
    private let revenueKey = "monthlyRevenue"
    private let currentMonthKey = "currentMonthRevenue"
    
    private init() {
        // Inisialisasi kosong
    }
    
    // Update the widget data with the latest monthly revenue
    func updateMonthlyRevenue(amount: Int, previousAmount: Int, date: Date) {
        // Calculate growth percentage
        let growth: Double
        if previousAmount > 0 {
            growth = Double(amount - previousAmount) / Double(previousAmount) * 100
        } else {
            growth = 0
        }
        
        // Tentukan apakah ini bulan saat ini
        let isCurrentMonth = isDateCurrentMonth(date)
        
        // Create revenue model and save it
        let revenue = MonthlyRevenue(
            amount: amount, 
            growth: growth, 
            date: date,
            previousAmount: previousAmount,
            isLatestMonth: isCurrentMonth
        )
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(revenue)
            
            guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
                return
            }
            
            // Simpan data normal di revenueKey
            sharedDefaults.set(data, forKey: revenueKey)
            
            // Jika ini bulan saat ini, simpan juga di currentMonthKey
            if isCurrentMonth {
                sharedDefaults.set(data, forKey: currentMonthKey)
            }
            
            sharedDefaults.synchronize()
            
            // Trigger widget refresh
            #if os(iOS)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        } catch {
            // Handle error silently
        }
    }
    
    // Cek apakah tanggal yang diberikan adalah bulan saat ini
    private func isDateCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        let currentComponents = calendar.dateComponents([.year, .month], from: now)
        
        return dateComponents.year == currentComponents.year && 
               dateComponents.month == currentComponents.month
    }
    
    // Dapatkan data bulan terakhir (bulan saat ini)
    func getCurrentMonthData() -> MonthlyRevenue? {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = sharedDefaults.data(forKey: currentMonthKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let revenue = try decoder.decode(MonthlyRevenue.self, from: data)
            return revenue
        } catch {
            return nil
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