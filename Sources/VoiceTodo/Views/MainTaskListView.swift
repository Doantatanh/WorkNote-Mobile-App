import SwiftUI
import UIKit

public struct MainTaskListView: View {
    @StateObject private var taskManager = TaskManager()
    @StateObject private var player = AudioPlayerService()
    @StateObject private var authService = AuthService()

    @State private var selectedTab: Int = 0 // 0: Việc, 1: Lịch, 2: Bóc băng, 3: Hồ sơ
    @State private var showingNewTaskSheet = false
    @State private var selectedTaskForDetail: TaskItem?

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Dark Background like the preview design
            Color(red: 0.05, green: 0.06, blue: 0.08)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Dynamic Top Content based on Selected Tab
                if selectedTab == 0 {
                    tasksMainView
                } else if selectedTab == 1 {
                    calendarPlaceholderView
                } else if selectedTab == 2 {
                    voiceMemoPlaceholderView
                } else {
                    profileView
                }

                Spacer(minLength: 80) // Space for bottom tab bar
            }

            // Floating Bottom Tab Bar with Big Orange Plus Button
            customBottomTabBar
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingNewTaskSheet) {
            NewTaskSheet(taskManager: taskManager)
        }
        .sheet(item: $selectedTaskForDetail) { task in
            TaskDetailView(task: task, taskManager: taskManager, player: player)
        }
    }

    // MARK: - 1. MAIN TASKS TAB VIEW
    private var tasksMainView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Top Mini Status / App Brand
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .foregroundColor(.orange)
                            .font(.system(size: 14, weight: .bold))
                        Text("WorkNote")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("v2.5")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                        Text("Online")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Header Progress Card: "2/4 việc hoàn thành" with Circular Ring
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(taskManager.completedCount)/\(max(1, taskManager.totalCount)) việc hoàn thành")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        HStack(alignment: .top, spacing: 5) {
                            Text("🔔")
                                .font(.system(size: 12))
                            Text("Hệ thống iOS sẽ nhắc bạn khi sắp đến hạn")
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75))
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    // Circular Progress Ring (Tím / Indigo)
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 5)
                            .frame(width: 52, height: 52)

                        Circle()
                            .trim(from: 0, to: CGFloat(taskManager.progressPercentage))
                            .stroke(
                                LinearGradient(
                                    colors: [Color.indigo, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .frame(width: 52, height: 52)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(taskManager.progressPercentage * 100))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(16)
                .background(Color(red: 0.09, green: 0.11, blue: 0.15))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 16)

                // Filter Pill Bar: Tất cả (viên thuốc trắng) | Cần làm | Đã xong
                HStack(spacing: 12) {
                    filterPill(title: "Tất cả", isSelected: taskManager.selectedFilter == .all) {
                        taskManager.selectedFilter = .all
                    }

                    filterPill(title: "Cần làm", isSelected: taskManager.selectedFilter == .pending) {
                        taskManager.selectedFilter = .pending
                    }

                    filterPill(title: "Đã xong", isSelected: taskManager.selectedFilter == .completed) {
                        taskManager.selectedFilter = .completed
                    }

                    Spacer()

                    Text("\(taskManager.filteredTasks.count) nhiệm vụ")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.5, green: 0.55, blue: 0.65))
                }
                .padding(.horizontal, 18)

                // Task Cards List
                if taskManager.filteredTasks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                        Text("Không có công việc nào")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(taskManager.filteredTasks) { task in
                            darkModernTaskCard(task: task)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
    }

    private func filterPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(isSelected ? Color.white : Color.clear)
                .foregroundColor(isSelected ? Color.black : Color(red: 0.55, green: 0.6, blue: 0.7))
                .cornerRadius(20)
        }
    }

    // MARK: - Dark Modern Task Card (Exact Match with Prototype)
    private func darkModernTaskCard(task: TaskItem) -> some View {
        Button(action: { selectedTaskForDetail = task }) {
            VStack(alignment: .leading, spacing: 12) {
                // Top Tag Row: Category badge + Báo ngầm badge + Time
                HStack(spacing: 8) {
                    // Category Tag
                    Text(task.category.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(task.category.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(task.category.color.opacity(0.18))
                        .cornerRadius(12)

                    // Notification Badge
                    HStack(spacing: 3) {
                        Text("🔔")
                            .font(.system(size: 9))
                        Text("Báo ngầm")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Color.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(10)

                    Spacer()

                    // Due Date / Time
                    if let due = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(formatDueDate(due))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(Color(red: 0.55, green: 0.6, blue: 0.7))
                    }
                }

                // Title + Checkbox Row
                HStack(alignment: .top, spacing: 12) {
                    Button(action: {
                        taskManager.toggleTask(id: task.id)
                    }) {
                        ZStack {
                            Circle()
                                .stroke(task.isCompleted ? Color(red: 0.15, green: 0.78, blue: 0.55) : Color.white.opacity(0.2), lineWidth: 2)
                                .frame(width: 22, height: 22)

                            if task.isCompleted {
                                Circle()
                                    .fill(Color(red: 0.15, green: 0.78, blue: 0.55))
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
                            .font(.system(size: 15, weight: .bold))
                            .strikethrough(task.isCompleted, color: Color.gray)
                            .foregroundColor(task.isCompleted ? Color(red: 0.45, green: 0.5, blue: 0.6) : Color.white)
                            .lineLimit(2)

                        if !task.note.isEmpty {
                            Text(task.note)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.55, green: 0.6, blue: 0.7))
                                .lineLimit(2)
                        }
                    }
                }

                // Voice Recording Info Pill (If has audio)
                if let audioFileName = task.audioFileName, !audioFileName.isEmpty {
                    HStack(spacing: 12) {
                        Button(action: {
                            player.playAudio(fileName: audioFileName)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: (player.playingFileName == audioFileName && player.isPlaying) ? "pause.fill" : "play.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text(formatDuration(task.audioDuration))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(Color.indigo)
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())

                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Supabase Voice")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.green)
                        }

                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(Color(red: 0.09, green: 0.11, blue: 0.15))
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 2. PROFILE VIEW (Hồ sơ)
    private var profileView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // User Avatar + Full Name Card
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.indigo, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)

                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Đoàn Tất Anh")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text("vandat3511@gmail.com")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.55, green: 0.6, blue: 0.7))

                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Supabase Cloud Connected")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.green)
                        }
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color(red: 0.09, green: 0.11, blue: 0.15))
                .cornerRadius(18)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Background Notifications Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("🔔")
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Thông báo ngầm (Không cần mở app)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text("iOS tự động đẩy banner trên Màn hình khóa")
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.55, green: 0.6, blue: 0.7))
                        }
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .toggleStyle(SwitchToggleStyle(tint: .indigo))
                            .labelsHidden()
                    }

                    HStack {
                        Text("Thời gian nhắc trước:")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.55, green: 0.6, blue: 0.7))
                        Spacer()
                        Text("15 phút trước giờ G")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.indigo)
                    }
                }
                .padding(16)
                .background(Color(red: 0.09, green: 0.11, blue: 0.15))
                .cornerRadius(18)
                .padding(.horizontal, 16)

                // Supabase Project Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Supabase Project: vkxjorgfqnkhazzntgbt")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Bảng tasks & Bucket voice-recordings đã kết nối.")
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.55, green: 0.6, blue: 0.7))
                        }
                        Spacer()
                        Text("Live")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                .padding(16)
                .background(Color(red: 0.09, green: 0.11, blue: 0.15))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)

                // Action Buttons: Đổi tài khoản / Đăng xuất
                VStack(spacing: 10) {
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Đổi tài khoản / Đăng nhập tài khoản khác")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.06))
                        .foregroundColor(Color.white)
                        .cornerRadius(12)
                    }

                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Đăng xuất tài khoản")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(Color.red)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Calendar & Voice Memo Placeholders
    private var calendarPlaceholderView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Lịch công việc thông minh")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text("Toàn bộ hạn chót sẽ hiển thị theo dòng thời gian tại đây.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var voiceMemoPlaceholderView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 54))
                .foregroundColor(.orange)
            Text("Kho bản ghi âm & Bóc băng")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text("Nghe lại các bản thu thoại của bạn bất cứ lúc nào.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Custom Bottom Tab Bar with Glowing Orange (+) Button
    private var customBottomTabBar: some View {
        ZStack(alignment: .top) {
            // Tab Bar Background
            HStack(spacing: 0) {
                // Tab 0: Việc
                tabBarItem(title: "Việc", icon: "house.fill", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }

                // Tab 1: Lịch
                tabBarItem(title: "Lịch", icon: "calendar", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }

                Spacer().frame(width: 72) // Space for big center button

                // Tab 2: Bóc băng
                tabBarItem(title: "Bóc băng", icon: "mic.fill", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }

                // Tab 3: Hồ sơ
                tabBarItem(title: "Hồ sơ", icon: "person.fill", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 22)
            .background(Color(red: 0.08, green: 0.09, blue: 0.12))
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 14)

            // Center Orange Glowing Plus Button
            Button(action: {
                showingNewTaskSheet = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color(red: 0.95, green: 0.45, blue: 0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .shadow(color: Color.orange.opacity(0.55), radius: 10, x: 0, y: 5)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -14)
        }
    }

    private func tabBarItem(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? Color.orange : Color(red: 0.5, green: 0.55, blue: 0.65))

                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? Color.orange : Color(red: 0.5, green: 0.55, blue: 0.65))
            }
            .frame(maxWidth: .infinity)
        }
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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
