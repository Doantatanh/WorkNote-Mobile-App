import Foundation
import Combine
import SwiftUI

public enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "Tất cả"
    case pending = "Cần làm"
    case completed = "Đã xong"

    public var id: String { rawValue }
}

public class TaskManager: ObservableObject {
    @Published public var tasks: [TaskItem] = []
    @Published public var selectedFilter: TaskFilter = .all
    @Published public var searchQuery: String = ""
    @Published public var selectedCategory: TaskCategory? = nil

    private let saveFileURL: URL

    public init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        self.saveFileURL = paths[0].appendingPathComponent("tasks.json")
        loadTasks()
    }

    public var filteredTasks: [TaskItem] {
        tasks.filter { task in
            // Filter by completion status
            let matchesStatus: Bool
            switch selectedFilter {
            case .all:
                matchesStatus = true
            case .pending:
                matchesStatus = !task.isCompleted
            case .completed:
                matchesStatus = task.isCompleted
            }

            // Filter by category
            let matchesCategory: Bool
            if let cat = selectedCategory {
                matchesCategory = (task.category == cat)
            } else {
                matchesCategory = true
            }

            // Filter by search query
            let matchesSearch: Bool
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                let query = searchQuery.lowercased()
                matchesSearch = task.title.lowercased().contains(query)
                    || task.note.lowercased().contains(query)
                    || (task.transcribedText?.lowercased().contains(query) ?? false)
            }

            return matchesStatus && matchesCategory && matchesSearch
        }.sorted { (t1, t2) -> Bool in
            // Active tasks first, then by date
            if t1.isCompleted != t2.isCompleted {
                return !t1.isCompleted
            }
            return t1.createdAt > t2.createdAt
        }
    }

    public var totalCount: Int {
        tasks.count
    }

    public var completedCount: Int {
        tasks.filter { $0.isCompleted }.count
    }

    public var pendingCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    public var progressPercentage: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(tasks.count)
    }

    public func addTask(_ task: TaskItem) {
        tasks.insert(task, at: 0)
        saveTasks()
        if !task.isCompleted {
            NotificationService.shared.scheduleTaskReminder(for: task)
        }
    }

    public func updateTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
            if task.isCompleted {
                NotificationService.shared.cancelTaskReminder(for: task)
            } else {
                NotificationService.shared.scheduleTaskReminder(for: task)
            }
        }
    }

    public func toggleTask(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
            let updatedTask = tasks[index]
            if updatedTask.isCompleted {
                NotificationService.shared.cancelTaskReminder(for: updatedTask)
            } else {
                NotificationService.shared.scheduleTaskReminder(for: updatedTask)
            }
        }
    }

    public func deleteTask(_ task: TaskItem) {
        NotificationService.shared.cancelTaskReminder(for: task)
        if let fileName = task.audioFileName {
            let audioURL = AudioRecorderService.audioURL(for: fileName)
            try? FileManager.default.removeItem(at: audioURL)
        }
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    public func deleteTask(at offsets: IndexSet) {
        for index in offsets {
            let task = filteredTasks[index]
            deleteTask(task)
        }
    }

    private func saveTasks() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(tasks)
            try data.write(to: saveFileURL, options: .atomic)
        } catch {
            print("Lỗi lưu danh sách công việc: \(error.localizedDescription)")
        }
    }

    private func loadTasks() {
        guard FileManager.default.fileExists(atPath: saveFileURL.path) else {
            // Seed with professional enterprise tasks
            self.tasks = [
                TaskItem(
                    code: "ENT-101",
                    title: "Báo cáo tiến độ triển khai quý 4 với Hội đồng Quản trị",
                    note: "Tổng hợp các chỉ số KPI, ngân sách giải ngân và phương án dự phòng rủi ro thị trường.",
                    isCompleted: false,
                    dueDate: Date().addingTimeInterval(3600 * 6),
                    priority: .high,
                    category: .executive,
                    assignee: "Nguyễn Hải Đăng (COO)",
                    audioFileName: "sample_recording_1.m4a",
                    audioDuration: 24,
                    transcribedText: "Yêu cầu phòng Tài chính hoàn thiện bảng cân đối kế toán trước 15h, chuẩn bị bản trình bày 10 trang cho ban điều hành.",
                    actionItems: [
                        "Chốt số liệu doanh thu trước 15h00",
                        "Rà soát slide thuyết trình cùng Giám đốc Tài chính",
                        "Gửi tài liệu mật qua cổng thông tin bảo mật nội bộ"
                    ]
                ),
                TaskItem(
                    code: "ENT-102",
                    title: "Ký kết thỏa thuận hợp tác chiến lược cùng đối tác Enterprise",
                    note: "Rà soát điều khoản bảo mật dữ liệu NDA và cam kết chất lượng dịch vụ SLA 99.9%.",
                    isCompleted: false,
                    dueDate: Date().addingTimeInterval(3600 * 24),
                    priority: .high,
                    category: .project,
                    assignee: "Trần Mai Anh (Head of Sales)",
                    audioFileName: nil,
                    audioDuration: 0,
                    transcribedText: nil,
                    actionItems: [
                        "Gửi bản dự thảo NDA bản song ngữ",
                        "Xác nhận lịch họp trực tiếp tại văn phòng trụ sở"
                    ]
                ),
                TaskItem(
                    code: "ENT-103",
                    title: "Đánh giá an toàn thông tin & Kiểm toán mã nguồn hệ thống",
                    note: "Thực hiện penetration test theo tiêu chuẩn ISO/IEC 27001 và SOC 2 Type II cho máy chủ lưu trữ.",
                    isCompleted: true,
                    dueDate: Date().addingTimeInterval(-3600 * 12),
                    priority: .medium,
                    category: .tech,
                    assignee: "Lê Quốc Bảo (Security Lead)",
                    audioFileName: "sample_recording_2.m4a",
                    audioDuration: 15,
                    transcribedText: "Đã rà soát xong toàn bộ 14 lỗ hổng bảo mật cấp trung và vá triệt để trước thời hạn cam kết.",
                    actionItems: [
                        "Cập nhật chứng chỉ TLS/SSL lên phiên bản 1.3",
                        "Xuất chứng nhận báo cáo kiểm toán cho Ban Giám đốc"
                    ]
                )
            ]
            saveTasks()
            return
        }

        do {
            let data = try Data(contentsOf: saveFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            self.tasks = try decoder.decode([TaskItem].self, from: data)
        } catch {
            print("Lỗi đọc danh sách công việc: \(error.localizedDescription)")
            self.tasks = []
        }
    }
}
