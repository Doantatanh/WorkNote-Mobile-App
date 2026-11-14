import SwiftUI

public struct AudioWaveformView: View {
    let levels: [CGFloat]
    let isRecording: Bool

    public init(levels: [CGFloat], isRecording: Bool) {
        self.levels = levels
        self.isRecording = isRecording
    }

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<levels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(isRecording ? Color.red : Color.blue.opacity(0.6))
                    .frame(width: 4, height: max(6, levels[index] * 40))
                    .animation(.easeInOut(duration: 0.1), value: levels[index])
            }
        }
        .frame(height: 44)
    }
}

public struct StatCardView: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    public init(title: String, count: Int, icon: String, color: Color) {
        self.title = title
        self.count = count
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Spacer()
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(color.opacity(0.12))
        .cornerRadius(12)
    }
}
