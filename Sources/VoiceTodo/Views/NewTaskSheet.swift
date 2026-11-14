import SwiftUI
import UIKit

public struct NewTaskSheet: View {
    @ObservedObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var recorder = AudioRecorderService()
    @StateObject private var speechRecognizer = SpeechRecognitionService()
    @StateObject private var player = AudioPlayerService()

    public enum InputMode: String, CaseIterable, Identifiable {
        case typing = "Gõ văn bản"
        case voice = "Nói / Ghi âm AI"
        public var id: String { rawValue }
    }

    @State private var inputMode: InputMode = .typing
    @State private var title: String = ""
    @State private var note: String = ""
    @State private var priority: Priority = .medium
    @State private var category: TaskCategory = .project
    @State private var assignee: String = "Tôi"
    @State private var hasDueDate: Bool = true
    @State private var dueDate: Date = Date().addingTimeInterval(3600 * 6)

    // Saved recording metadata (optional attachment)
    @State private var recordedFileName: String?
    @State private var recordedDuration: TimeInterval = 0

    public init(taskManager: TaskManager) {
        self.taskManager = taskManager
    }

    public var body: some View {
        NavigationView {
            Form {
                // Section 0: Select Input Method (Gõ tay hoặc Nói)
                Section {
                    Picker("Phương thức nhập", selection: $inputMode) {
                        HStack {
                            Image(systemName: "keyboard")
                            Text("Gõ văn bản")
                        }.tag(InputMode.typing)

                        HStack {
                            Image(systemName: "mic.fill")
                            Text("Nói / Voice AI")
                        }.tag(InputMode.voice)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // Section 1: Voice Recording (When in Voice mode or optional voice note)
                if inputMode == .voice || recordedFileName != nil {
                    Section(header: Text("Bóc băng giọng nói Voice AI")) {
                        VStack(spacing: 12) {
                            if recorder.isRecording {
                                VStack(spacing: 8) {
                                    HStack {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                        Text("Đang nghe: \(formatDuration(recorder.recordingDuration))")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.red)
                                    }

                                    AudioWaveformView(levels: recorder.currentAudioLevels, isRecording: true)

                                    if !speechRecognizer.transcribedText.isEmpty {
                                        Text("\"\(speechRecognizer.transcribedText)\"")
                                            .font(.system(size: 12))
                                            .italic()
                                            .foregroundColor(.primary)
                                            .padding(8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(8)
                                    }

                                    Button(action: stopRecording) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "stop.circle.fill")
                                            Text("Dừng & Tự điền vào việc")
                                        }
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.red)
                                        .cornerRadius(20)
                                    }
                                }
                                .padding(.vertical, 4)
                            } else if let _ = recordedFileName {
                                HStack {
                                    Image(systemName: "waveform.badge.checkmark")
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Đã đính kèm bản ghi âm (\(formatDuration(recordedDuration)))")
                                            .font(.system(size: 12, weight: .bold))
                                        Text("File âm thanh sẽ được đồng bộ lên Supabase")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button("Gỡ bỏ") {
                                        deleteCurrentRecording()
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.red)
                                }
                            } else {
                                HStack(spacing: 12) {
                                    Button(action: startRecording) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "mic.fill")
                                            Text("Bấm để nói")
                                        }
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 14)
                                        .background(Color.indigo)
                                        .cornerRadius(16)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Text("Nói để hệ thống tự động gõ tiêu đề & ghi chú")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Section 2: Typing Info (Tiêu đề & Ghi chú bằng bàn phím)
                Section(header: Text("Nội dung công việc (Gõ tay)")) {
                    HStack {
                        TextField("Nhập tiêu đề công việc...", text: $title)
                            .font(.system(size: 15, weight: .medium))

                        if inputMode == .typing && !recorder.isRecording && recordedFileName == nil {
                            Button(action: {
                                inputMode = .voice
                                startRecording()
                            }) {
                                Image(systemName: "mic.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.indigo)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    TextField("Mô tả chi tiết / Ghi chú thêm (tùy chọn)", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.system(size: 13))
                }

                // Section 3: Attributes (Mức độ ưu tiên & Khối)
                Section(header: Text("Thiết lập & Phân loại")) {
                    Picker("Mức độ ưu tiên", selection: $priority) {
                        ForEach(Priority.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }

                    Picker("Danh mục", selection: $category) {
                        ForEach(TaskCategory.allCases) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }

                    Toggle("Đặt thời hạn hoàn thành (Hạn chót)", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Hạn chót", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("Tạo công việc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") {
                        if recorder.isRecording { recorder.cancelRecording() }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu việc") {
                        saveTask()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func startRecording() {
        recorder.startRecording()
        speechRecognizer.startTranscribing()
    }

    private func stopRecording() {
        if let res = recorder.stopRecording() {
            recordedFileName = res.fileName
            recordedDuration = res.duration
        }
        speechRecognizer.stopTranscribing()
        if title.isEmpty && !speechRecognizer.transcribedText.isEmpty {
            title = speechRecognizer.transcribedText
        } else if !speechRecognizer.transcribedText.isEmpty {
            if note.isEmpty {
                note = speechRecognizer.transcribedText
            } else {
                note += "\n" + speechRecognizer.transcribedText
            }
        }
    }

    private func deleteCurrentRecording() {
        if let fileName = recordedFileName {
            let url = AudioRecorderService.audioURL(for: fileName)
            try? FileManager.default.removeItem(at: url)
        }
        recordedFileName = nil
        recordedDuration = 0
    }

    private func saveTask() {
        let code = "VT-\(Int.random(in: 100...999))"
        let task = TaskItem(
            code: code,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority,
            category: category,
            assignee: assignee,
            audioFileName: recordedFileName,
            audioDuration: recordedDuration,
            transcribedText: speechRecognizer.transcribedText.isEmpty ? nil : speechRecognizer.transcribedText,
            actionItems: []
        )
        taskManager.addTask(task)
        dismiss()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
