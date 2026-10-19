import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "timer") }
            HistoryView()
                .tabItem { Label("History", systemImage: "chart.bar") }
            ReportView()
                .tabItem { Label("Report", systemImage: "doc.text") }
        }
    }
}
