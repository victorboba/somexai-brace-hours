import SwiftUI

struct ProgressRing<Content: View>: View {
    let progress: Double
    var lineWidth: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Circle().stroke(Color.accentColor.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(progress >= 1 ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)
            content
        }
    }
}
