import SwiftUI
import Charts

/// Hours per day as bars with the goal as a line. Used in History and rendered into the PDF.
struct WearChart: View {
    let totals: [WearMath.DayTotal]
    let goalHours: Double

    var body: some View {
        Chart {
            ForEach(totals) { t in
                BarMark(x: .value("Day", t.day, unit: .day), y: .value("Hours", t.hours))
                    .foregroundStyle(t.hours >= goalHours ? Color.green : Color.accentColor)
                    .cornerRadius(3)
            }
            RuleMark(y: .value("Goal", goalHours))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                .foregroundStyle(.secondary)
                .annotation(position: .top, alignment: .trailing) {
                    Text("Goal \(Formatters.hours(goalHours))").font(.caption2).foregroundStyle(.secondary)
                }
        }
        .chartYScale(domain: 0...24)
        .chartYAxis {
            AxisMarks(values: [0, 6, 12, 18, 24]) { value in
                AxisGridLine()
                AxisValueLabel { if let v = value.as(Int.self) { Text("\(v)") } }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: totals.count > 20 ? 7 : totals.count > 10 ? 2 : 1)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
            }
        }
    }
}
