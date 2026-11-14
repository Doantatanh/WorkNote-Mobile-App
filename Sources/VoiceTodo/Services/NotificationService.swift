import Foundation
import UserNotifications

public class NotificationService: ObservableObject {
    public static let shared = NotificationService()

    @Published public var isAuthorized: Bool = false

    private init() {
        checkAuthorization()
    }

    /// Yêu cầu quyền gửi thông báo từ người dùng iOS
    public func requestPermission(completion: @escaping (Bool) -> Void = { _ in }) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }

    /// Kiểm tra trạng thái cấp quyền hiện tại
    public func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }

    /// Lên lịch thông báo nhắc việc sắp đến hạn (chạy ngầm bởi iOS, không cần mở app)
    /// - Parameters:
    ///   - task: Công việc cần nhắc
    ///   - minutesBefore: Nhắc trước hạn chót bao nhiêu phút (mặc định: 15 phút)
    public func scheduleTaskReminder(for task: TaskItem, minutesBefore: Int = 15) {
        guard let dueDate = task.dueDate else { return }

        // Tính thời điểm phát thông báo (ví dụ 15 phút trước giờ G)
        let triggerDate = dueDate.addingTimeInterval(TimeInterval(-minutesBefore * 60))

        // Nếu thời điểm thông báo đã qua trong quá khứ thì bỏ qua
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏰ Nhắc nhở công việc sắp đến hạn"
        content.subtitle = task.title
        content.body = task.note.isEmpty ? "Hạn chót vào lúc \(formatTime(dueDate)). Bấm để xem chi tiết." : task.note
        content.sound = .default
        content.badge = 1

        // Tạo trigger theo lịch của hệ điều hành iOS
        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "task_reminder_\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Lỗi lên lịch thông báo: \(error.localizedDescription)")
            } else {
                print("Đã lên lịch nhắc việc: \(task.title) lúc \(triggerDate)")
            }
        }
    }

    /// Hủy lịch nhắc nhở khi công việc đã hoàn thành hoặc bị xóa
    public func cancelTaskReminder(for task: TaskItem) {
        let identifier = "task_reminder_\(task.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
