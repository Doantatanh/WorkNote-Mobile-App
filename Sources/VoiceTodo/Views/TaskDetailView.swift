import SwiftUI
import UIKit

public struct TaskDetailView: View {
    @ObservedObject var taskManager: TaskManager
    @ObservedObject var player: AudioPlayerService
    @Environment(\.dismiss) private var dismiss

    @State private var task: TaskItem

    public init(task: TaskItem, taskManager: TaskManager, player: AudioPlayerService) {
        self._task = State(initialValue: task)
        self.taskManager = taskManager
        self.player = player
    }

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header Meta: Task Code & Status Toggle
                    HStack(alignment: .center) {
                        Text(task.code)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(6)

                        Spacer()

                        Button(action: toggleCompletion) {
                            HStack(spacing: 6) {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14, weight: .bold))
                                Text(task.isCompleted ? "ĐÃ HOÀN THÀNH" : "ĐANG XỬ LÝ (SLA)")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(task.isCompleted ? .green : .orange)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(task.isCompleted ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                            .cornerRadius(8)
                        }
                    }

                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)

                        if !task.note.isEmpty {
                            Text(task.note)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                    }

                    // Voice Audio Player Box
                    if let audioFileName = task.audioFileName, !audioFileName.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                HStack(spacing: 5) {
                                    Image(systemName: "waveform")
                                        .foregroundColor(.blue)
                                    Text("Biên bản ghi âm thoại")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                Spacer()
                                Text(player.speedLabel)
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(4)
                                    .onTapGesture {
                                        player.toggleSpeed()
                                    }
                            }

                            // Waveform / Scrubber
                            VStack(spacing: 6) {
                                ProgressView(value: player.currentProgress)
                                    .accentColor(.blue)

                                HStack {
                                    Text(formatDuration(player.currentTime))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatDuration(task.audioDuration))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }

                            // Playback controls
                            HStack(spacing: 24) {
                                Spacer()
                                Button(action: { player.skip(seconds: -5) }) {
                                    Image(systemName: "gobackward.5")
                                        .font(.system(size: 18))
                                }

                                Button(action: { player.playAudio(fileName: audioFileName) }) {
                                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                }

                                Button(action: { player.skip(seconds: 5) }) {
                                    Image(systemName: "goforward.5")
                                        .font(.system(size: 18))
                                }
                                Spacer()
                            }
                            .foregroundColor(.primary)

                            // AI Speech-to-Text transcript
                            if let transcript = task.transcribedText, !transcript.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 11))
                                            .foregroundColor(.purple)
                                        Text("Nội dung bóc băng Speech-to-Text:")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }

                                    Text("\"\(transcript)\"")
                                        .font(.system(size: 13, weight: .regular))
                                        .italic()
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(8)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(14)
                        .background(Color(.secondarySystemBackground).opacity(0.6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                    }

                    // Key Action Items Checklist
                    if !task.actionItems.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Đầu việc hành động (Action Items)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)

                            ForEach(task.actionItems, id: \.self) { item in
                                HStack(spacing: 8) {
                                    Image(systemName: "circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                    Text(item)
                                        .font(.system(size: 13))
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground).opacity(0.6))
                        .cornerRadius(12)
                    }

                    // Enterprise Metadata Info Grid
                    VStack(spacing: 10) {
                        detailRow(title: "Khối / Phòng ban", value: task.category.rawValue, icon: task.category.icon)
                        detailRow(title: "Mức độ ưu tiên", value: task.priority.rawValue, icon: task.priority.icon)
                        detailRow(title: "Phụ trách", value: task.assignee, icon: "person.crop.circle")
                        if let dueDate = task.dueDate {
                            detailRow(title: "Thời hạn SLA", value: formatFullDate(dueDate), icon: "calendar.badge.clock")
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground).opacity(0.6))
                    .cornerRadius(12)

                    // Delete button
                    Button(role: .destructive, action: deleteTask) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Xóa nhiệm vụ này")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
            .navigationTitle("Chi tiết nhiệm vụ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        player.stopAudio()
                        dismiss()
                    }
                }
            }
        }
    }

    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
        }
    }

    private func toggleCompletion() {
        taskManager.toggleTask(id: task.id)
        task.isCompleted.toggle()
    }

    private func deleteTask() {
        player.stopAudio()
        taskManager.deleteTask(task)
        dismiss()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm, dd 'tháng' MM, yyyy"
        return formatter.string(from: date)
    }
}
