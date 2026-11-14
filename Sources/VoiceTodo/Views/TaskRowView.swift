import SwiftUI
import UIKit

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
            VStack(alignment: .leading, spacing: 10) {
                // Top Meta Header: Code, Priority, Category
                HStack(alignment: .center, spacing: 6) {
                    Text(task.code)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.35, green: 0.38, blue: 0.44))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color(red: 0.94, green: 0.95, blue: 0.97))
                        .cornerRadius(6)

                    // Category
                    HStack(spacing: 4) {
                        Image(systemName: task.category.icon)
                            .font(.system(size: 9))
                        Text(task.category.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(task.category.color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(task.category.color.opacity(0.12))
                    .cornerRadius(6)

                    Spacer()

                    // Priority Badge
                    HStack(spacing: 3) {
                        Image(systemName: task.priority.icon)
                            .font(.system(size: 9))
                        Text(task.priority.rawValue)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(task.priority.color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(task.priority.color.opacity(0.12))
                    .cornerRadius(6)
                }

                // Middle: Checkbox + Title
                HStack(alignment: .top, spacing: 12) {
                    Button(action: onToggle) {
                        ZStack {
                            Circle()
                                .stroke(task.isCompleted ? Color.green : Color(red: 0.8, green: 0.82, blue: 0.86), lineWidth: 2)
                                .frame(width: 22, height: 22)
                            if task.isCompleted {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 22, height: 22)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.system(size: 15, weight: .semibold))
                            .strikethrough(task.isCompleted, color: Color(red: 0.65, green: 0.68, blue: 0.72))
                            .foregroundColor(task.isCompleted ? Color(red: 0.6, green: 0.62, blue: 0.66) : Color(red: 0.1, green: 0.12, blue: 0.15))
                            .lineLimit(2)

                        if !task.note.isEmpty {
                            Text(task.note)
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.45, green: 0.48, blue: 0.54))
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
                            HStack(spacing: 6) {
                                Image(systemName: isCurrentlyPlayingThisAudio ? "pause.fill" : "play.fill")
                                    .font(.system(size: 10, weight: .bold))
                                Text(isCurrentlyPlayingThisAudio ? "Đang phát..." : formatDuration(task.audioDuration))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                isCurrentlyPlayingThisAudio
                                ? LinearGradient(colors: [Color.orange, Color(red: 0.95, green: 0.45, blue: 0.1)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color(red: 0.98, green: 0.94, blue: 0.9), Color(red: 0.98, green: 0.94, blue: 0.9)], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(isCurrentlyPlayingThisAudio ? .white : Color.orange)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if let transcript = task.transcribedText, !transcript.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 9))
                                    .foregroundColor(.purple)
                                Text("Biên bản AI")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(red: 0.45, green: 0.48, blue: 0.54))
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 2)
                }

                // Bottom Meta: Assignee + Due Date
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.65, green: 0.68, blue: 0.72))
                        Text(task.assignee)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 0.45, green: 0.48, blue: 0.54))
                    }

                    Spacer()

                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text(formatDueDate(dueDate))
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(dueDate < Date() && !task.isCompleted ? Color.red : Color(red: 0.5, green: 0.53, blue: 0.58))
                    }
                }
                .padding(.top, 2)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.92, green: 0.94, blue: 0.96), lineWidth: 1)
            )
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
