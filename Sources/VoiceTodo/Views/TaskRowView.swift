import SwiftUI

public struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void
    @ObservedObject var player: AudioPlayerService
    let onSelect: () -> Void

    public init(
        task: TaskItem,
        player: AudioPlayerService,
        onToggle: @escaping () -> Void,
        onSelect: @escaping () -> Void
    ) {
        self.task = task
        self.player = player
        self.onToggle = onToggle
        self.onSelect = onSelect
    }

    private var isCurrentlyPlayingThisAudio: Bool {
        guard let fileName = task.audioFileName else { return false }
        return player.playingFileName == fileName && player.isPlaying
    }

    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                // Top Meta Header: Code, Priority, Category
                HStack(alignment: .center, spacing: 6) {
                    Text(task.code)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(4)

                    // Category
                    HStack(spacing: 3) {
                        Image(systemName: task.category.icon)
                            .font(.system(size: 9))
                        Text(task.category.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(task.category.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(task.category.color.opacity(0.12))
                    .cornerRadius(4)

                    Spacer()

                    // Priority Badge
                    HStack(spacing: 3) {
                        Image(systemName: task.priority.icon)
                            .font(.system(size: 9))
                        Text(task.priority.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(task.priority.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(task.priority.color.opacity(0.12))
                    .cornerRadius(4)
                }

                // Middle: Checkbox + Title
                HStack(alignment: .top, spacing: 10) {
                    Button(action: onToggle) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundColor(task.isCompleted ? Color.green : Color.secondary.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.system(size: 15, weight: .semibold))
                            .strikethrough(task.isCompleted, color: .gray)
                            .foregroundColor(task.isCompleted ? .secondary : .primary)
                            .lineLimit(2)

                        if !task.note.isEmpty {
                            Text(task.note)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }

                // Voice Memo Mini Player (If has audio)
                if let audioFileName = task.audioFileName, !audioFileName.isEmpty {
                    HStack(spacing: 8) {
                        Button(action: {
                            player.playAudio(fileName: audioFileName)
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: isCurrentlyPlayingThisAudio ? "pause.fill" : "play.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text(isCurrentlyPlayingThisAudio ? "Đang phát..." : formatDuration(task.audioDuration))
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isCurrentlyPlayingThisAudio ? Color.blue : Color.blue.opacity(0.12))
                            .foregroundColor(isCurrentlyPlayingThisAudio ? .white : Color.blue)
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if let transcript = task.transcribedText, !transcript.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 9))
                                    .foregroundColor(.purple)
                                Text("Biên bản AI")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 2)
                }

                // Bottom Meta: Assignee + Due Date
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 11))
                        Text(task.assignee)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)

                    Spacer()

                    if let dueDate = task.dueDate {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(formatDueDate(dueDate))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(dueDate < Date() && !task.isCompleted ? Color.red : Color.secondary)
                    }
                }
                .padding(.top, 2)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm 'Hôm nay'"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "HH:mm 'Ngày mai'"
        } else {
            formatter.dateFormat = "dd/MM/yyyy"
        }
        return formatter.string(from: date)
    }
}
