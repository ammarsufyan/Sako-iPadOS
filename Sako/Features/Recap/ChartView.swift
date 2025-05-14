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
    
    var body: some View {
        Chart {
            ForEach(data) { item in
                LineMark(
                    x: .value("Minggu", item.week),
                    y: .value("Nilai", item.value)
                )
                .foregroundStyle(Color.green.gradient)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                PointMark(
                    x: .value("Minggu", item.week),
                    y: .value("Nilai", item.value)
                )
                .foregroundStyle(Color.green)
                .symbolSize(30)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let intValue = value.as(Int.self) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                        .foregroundStyle(Color.gray.opacity(0.5))
                    
                    AxisValueLabel {
                        if intValue == 0 {
                            Text("Rp 0")
                        } else if intValue == 500000 {
                            Text("Rp 500 ribu")
                        } else if intValue == 1000000 {
                            Text("Rp 1 juta")
                        } else if intValue == 5000000 {
                            Text("Rp 5 juta")
                        } else if intValue == 10000000 {
                            Text("Rp 10 juta")
                        } else {
                            Text("Rp \(formatPrice(intValue))")
                        }
                    }
                    .foregroundStyle(Color.secondary)
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                    .foregroundStyle(Color.gray.opacity(0.5))
                AxisValueLabel()
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartYScale(range: .plotDimension(padding: 10))
        .chartXScale(range: .plotDimension(padding: 10))
        .padding(.leading, 0)
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
    
    var body: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("Minggu", item.week),
                    y: .value("Nilai", item.value)
                )
                .foregroundStyle(Color.green)
                .cornerRadius(4)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                    .foregroundStyle(Color.gray.opacity(0.5))
                AxisValueLabel()
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                    .foregroundStyle(Color.gray.opacity(0.5))
                AxisValueLabel()
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartYScale(range: .plotDimension(padding: 10))
        .chartXScale(range: .plotDimension(padding: 10))
        .padding(.leading, 0)
    }
}
