import SwiftUI

struct RingProgress: View {
    var progress: Double // 0...1
    var size: CGFloat = 260
    var lineWidth: CGFloat = 14
    var tint: Color = Theme.primary
    var track: Color = Color.white.opacity(0.15)

    var body: some View {
        ZStack {
            Circle()
                .stroke(track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(1, progress))))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack { Color.black.ignoresSafeArea(); RingProgress(progress: 0.66) }
}

