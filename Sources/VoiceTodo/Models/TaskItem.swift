import Foundation
import SwiftUI

public enum Priority: String, Codable, CaseIterable, Identifiable {
    case high = "P1 - Khẩn cấp"
    case medium = "P2 - Trọng tâm"
    case low = "P3 - Tiêu chuẩn"

    public var id: String { rawValue }

    public var shortLabel: String {
        switch self {
        case .high: return "P1"
        case .medium: return "P2"
        case .low: return "P3"
        }
    }

    public var color: Color {
        switch self {
        case .high: return Color(red: 0.95, green: 0.25, blue: 0.25)
        case .medium: return Color(red: 0.95, green: 0.65, blue: 0.15)
        case .low: return Color(red: 0.25, green: 0.55, blue: 0.95)
        }
    }

    public var icon: String {
        switch self {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "flag.fill"
        case .low: return "circle"
        }
    }
}

public enum TaskCategory: String, Codable, CaseIterable, Identifiable {
    case project = "Dự án & Khách hàng"
    case executive = "Ban điều hành & Họp"
    case tech = "Kỹ thuật & R&D"
    case finance = "Tài chính & Pháp lý"
    case ops = "Vận hành nội bộ"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .project: return "briefcase.fill"
        case .executive: return "person.3.sequence.fill"
        case .tech: return "terminal.fill"
        case .finance: return "chart.line.uptrend.xyaxis"
        case .ops: return "gearshape.2.fill"
        }
    }

    public var color: Color {
        switch self {
        case .project: return Color.blue
        case .executive: return Color.purple
        case .tech: return Color.indigo
        case .finance: return Color.teal
        case .ops: return Color.gray
        }
    }
}

public struct TaskItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var code: String
    public var title: String
    public var note: String
    public var isCompleted: Bool
    public var createdAt: Date
    public var dueDate: Date?
    public var priority: Priority
    public var category: TaskCategory
    public var assignee: String
    public var audioFileName: String?
    public var audioDuration: TimeInterval
    public var transcribedText: String?
    public var actionItems: [String]

    public init(
        id: UUID = UUID(),
        code: String = "ENT-\(Int.random(in: 100...999))",
        title: String,
        note: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        dueDate: Date? = nil,
        priority: Priority = .medium,
        category: TaskCategory = .project,
        assignee: String = "Ban Quản lý Dự án",
        audioFileName: String? = nil,
        audioDuration: TimeInterval = 0,
        transcribedText: String? = nil,
        actionItems: [String] = []
    ) {
        self.id = id
        self.code = code
        self.title = title
        self.note = note
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.priority = priority
        self.category = category
        self.assignee = assignee
        self.audioFileName = audioFileName
        self.audioDuration = audioDuration
        self.transcribedText = transcribedText
        self.actionItems = actionItems
    }

    public var hasAudio: Bool {
        guard let name = audioFileName else { return false }
        return !name.isEmpty
    }
}
