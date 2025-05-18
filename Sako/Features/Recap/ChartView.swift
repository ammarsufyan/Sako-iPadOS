import SwiftUI
import Charts

// Model data untuk charts
struct WeeklyData: Identifiable {
    let id = UUID()
    let week: String
    let value: Int
}

struct LineChartView: View {
    var data: [WeeklyData]
    @State private var selectedWeek: String?
    
    // Get the selected data point
    private var selectedWeekData: WeeklyData? {
        guard let selectedWeek else { return nil }
        return data.first { $0.week == selectedWeek }
    }
    
    var body: some View {
        Chart {
            ForEach(data) { item in
                LineMark(
                    x: .value("Minggu", item.week),
                    y: .value("Nilai", item.value)
                )
                .foregroundStyle(Color.green)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .opacity(selectedWeek == nil || item.week == selectedWeekData?.week ? 1 : 0.3)
                
                PointMark(
                    x: .value("Minggu", item.week),
                    y: .value("Nilai", item.value)
                )
                .foregroundStyle(Color.green)
                .symbolSize(30)
                .opacity(selectedWeek == nil || item.week == selectedWeekData?.week ? 1 : 0.3)
                
                // Annotation for selected point
                if let selectedData = selectedWeekData, selectedData.week == item.week {
                    PointMark(
                        x: .value("Minggu", item.week),
                        y: .value("Nilai", item.value)
                    )
                    .opacity(0)
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        VStack(spacing: 2) {
                            Text(item.week)
                                .font(.system(size: 14, weight: .medium))
                            Text("Rp\(formatPrice(item.value))")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.green)
                        )
                    }
                }
            }
        }
        .chartXSelection(value: $selectedWeek.animation(nil))
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let intValue = value.as(Int.self) {
                    AxisGridLine()
                        .foregroundStyle(Color.gray.opacity(0.5))
                    
                    AxisValueLabel {
                        if intValue == 0 {
                            Text("Rp0")
                        } else if intValue < 1_000_000 {
                            // Untuk nilai di bawah 1 juta, bulatkan ke 100 ribu terdekat
                            let roundedHundredThousands = (intValue + 50_000) / 100_000
                            Text("Rp\(roundedHundredThousands * 100) Ribu")
                        } else {
                            // Untuk nilai 1 juta ke atas, bulatkan ke 1 juta terdekat
                            let roundedMillions = (intValue + 500_000) / 1_000_000
                            Text("Rp\(roundedMillions) Juta")
                        }
                    }
                    .foregroundStyle(Color.black)
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.5))
                AxisValueLabel()
                    .foregroundStyle(Color.black)
            }
        }
        .frame(height: 150)
        .chartLegend(.hidden)
    }
    
    private func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

struct BarChartView: View {
    var data: [WeeklyData]
    @State private var selectedWeek: String?
    
    // Get the selected data point
    private var selectedWeekData: WeeklyData? {
        guard let selectedWeek else { return nil }
        return data.first { $0.week == selectedWeek }
    }
    
    var body: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("Minggu", item.week),
                    y: .value("Nilai", item.value)
                )
                .foregroundStyle(Color.green)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .opacity(selectedWeek == nil || item.week == selectedWeekData?.week ? 1 : 0.3)
                
                // Annotation for selected bar
                if let selectedData = selectedWeekData, selectedData.week == item.week {
                    PointMark(
                        x: .value("Minggu", item.week),
                        y: .value("Nilai", item.value)
                    )
                    .opacity(0)
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        VStack(spacing: 2) {
                            Text(item.week)
                                .font(.system(size: 14, weight: .medium))
                            Text("\(item.value)")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.green)
                        )
                    }
                }
            }
        }
        .chartXSelection(value: $selectedWeek.animation(nil))
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.5))
                AxisValueLabel()
                    .foregroundStyle(Color.black)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.5))
                AxisValueLabel()
                    .foregroundStyle(Color.black)
            }
        }
        .frame(height: 150)
        .chartLegend(.hidden)
    }
}
