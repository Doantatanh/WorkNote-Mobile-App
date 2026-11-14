import Foundation

public class SupabaseSyncService: ObservableObject {
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncDate: Date?
    @Published public var syncStatusMessage: String = "Đã đồng bộ cục bộ"

    public static let shared = SupabaseSyncService()

    private init() {}

    /// Đồng bộ danh sách công việc lên Supabase Database
    public func syncTasks(_ tasks: [TaskItem], user: AuthUser?) async -> Bool {
        guard let user = user, let token = user.accessToken else {
            await MainActor.run {
                self.syncStatusMessage = "Chế độ Offline (Chưa đăng nhập)"
            }
            return false
        }

        await MainActor.run {
            self.isSyncing = true
            self.syncStatusMessage = "Đang đồng bộ với Supabase..."
        }

        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/tasks") else {
            await MainActor.run { self.isSyncing = false }
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // Upsert mode in PostgREST
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        // Prepare records
        let records = tasks.map { task -> [String: Any] in
            var dict: [String: Any] = [
                "id": task.id.uuidString,
                "user_id": user.id,
                "title": task.title,
                "note": task.note,
                "is_completed": task.isCompleted,
                "priority": task.priority.rawValue,
                "category": task.category.rawValue,
                "audio_duration": task.audioDuration,
                "created_at": ISO8601DateFormatter().string(from: task.createdAt)
            ]
            if let transcript = task.transcribedText {
                dict["transcribed_text"] = transcript
            }
            if let due = task.dueDate {
                dict["due_date"] = ISO8601DateFormatter().string(from: due)
            }
            return dict
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: records)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                await MainActor.run {
                    self.isSyncing = false
                    self.lastSyncDate = Date()
                    self.syncStatusMessage = "Đồng bộ Supabase thành công 🟢"
                }
                return true
            } else {
                await MainActor.run {
                    self.isSyncing = false
                    self.syncStatusMessage = "Lỗi đồng bộ máy chủ"
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.isSyncing = false
                self.syncStatusMessage = "Lỗi kết nối mạng"
            }
            return false
        }
    }
}
