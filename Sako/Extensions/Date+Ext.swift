import Foundation

extension Date {
    func isFutureDate() -> Bool {
        return self > Date()
    }
    
    func isPastDate() -> Bool {
        return self < Date()
    }
    
    func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    func toMonthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: self)
    }
}
