import SwiftUI
import UIKit

public struct MainTaskListView: View {
    @StateObject private var taskManager = TaskManager()
    @StateObject private var player = AudioPlayerService()
    @StateObject private var authService = AuthService()

    @State private var showingNewTaskSheet = false
    @State private var showingAuthSheet = false
    @State private var selectedTaskForDetail: TaskItem?

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                // Background
                Color(red: 0.97, green: 0.975, blue: 0.985)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top App Bar with Logo & WorkNote Branding
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.orange, Color(red: 0.95, green: 0.45, blue: 0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 34, height: 34)
                                    .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)

                                Image(systemName: "waveform")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text("WorkNote")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.1, green: 0.12, blue: 0.15))
                                Text("Quản lý thoại & công việc")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(red: 0.55, green: 0.58, blue: 0.63))
                            }
                        }

                        Spacer()

                        // Cloud Sync / Auth Button
                        Button(action: {
                            showingAuthSheet = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: authService.isAuthenticated ? "icloud.fill" : "person.crop.circle")
                                    .font(.system(size: 13))
                                Text(authService.isAuthenticated ? "Đồng bộ" : "Đăng nhập")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .foregroundColor(Color.orange)
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                    // Enterprise Workspace & KPI Dashboard Header
                    dashboardHeaderView
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)

                    // Search Input Box
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(red: 0.6, green: 0.63, blue: 0.68))
                            .font(.system(size: 14))

                        TextField("Tìm kiếm theo mã, tiêu đề, nội dung...", text: $taskManager.searchQuery)
                            .font(.system(size: 13))

                        if !taskManager.searchQuery.isEmpty {
                            Button(action: { taskManager.searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 13))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    // Filter segmented control
                    Picker("Trạng thái", selection: $taskManager.selectedFilter) {
                        ForEach(TaskFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    // Department / Category Horizontal Filter
                    categoryFilterScrollView
                        .padding(.bottom, 8)

                    // Task List or Empty View
                    if taskManager.filteredTasks.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(taskManager.filteredTasks) { task in
                                    TaskRowView(
                                        task: task,
                                        player: player,
                                        onToggle: {
                                            taskManager.toggleTask(id: task.id)
                                        },
                                        onSelect: {
                                            selectedTaskForDetail = task
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .padding(.bottom, 90)
                        }
                    }
                }

                // Executive Floating Action Button
                Button(action: {
                    showingNewTaskSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Ghi âm / Thêm việc")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 22)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color(red: 0.92, green: 0.38, blue: 0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(28)
                    .shadow(color: Color.orange.opacity(0.45), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewTaskSheet) {
                NewTaskSheet(taskManager: taskManager)
            }
            .sheet(isPresented: $showingAuthSheet) {
                AuthView(authService: authService)
            }
            .sheet(item: $selectedTaskForDetail) { task in
                TaskDetailView(task: task, taskManager: taskManager, player: player)
            }
        }
    }

    // MARK: - Enterprise KPI Dashboard
    private var dashboardHeaderView: some View {
        VStack(spacing: 12) {
            // Stats Row
            HStack(spacing: 10) {
                enterpriseKpiCard(
                    title: "Tổng việc",
                    count: "\(taskManager.totalCount)",
                    subtitle: "Đầu việc mở",
                    color: Color(red: 0.15, green: 0.18, blue: 0.22)
                )

                enterpriseKpiCard(
                    title: "Chờ xử lý",
                    count: "\(taskManager.pendingCount)",
                    subtitle: "Cần làm gấp",
                    color: Color.orange
                )

                enterpriseKpiCard(
                    title: "Hoàn thành",
                    count: "\(taskManager.completedCount)",
                    subtitle: "\(Int(taskManager.progressPercentage * 100))% chỉ tiêu",
                    color: Color(red: 0.12, green: 0.65, blue: 0.38)
                )
            }

            // Enterprise SLA Progress bar
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Tiến độ giải quyết công việc")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 0.45, green: 0.48, blue: 0.54))
                    Spacer()
                    Text("\(Int(taskManager.progressPercentage * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.1, green: 0.12, blue: 0.15))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.9, green: 0.92, blue: 0.95))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color(red: 0.95, green: 0.55, blue: 0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * CGFloat(taskManager.progressPercentage)), height: 6)
                            .animation(.spring(), value: taskManager.progressPercentage)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(red: 0.92, green: 0.94, blue: 0.96), lineWidth: 1)
        )
    }

    private func enterpriseKpiCard(title: String, count: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(red: 0.5, green: 0.53, blue: 0.58))
                .lineLimit(1)

            Text(count)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(Color(red: 0.6, green: 0.63, blue: 0.68))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(red: 0.975, green: 0.98, blue: 0.99))
        .cornerRadius(12)
    }

    // MARK: - Department / Category Filter Bar
    private var categoryFilterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: {
                    taskManager.selectedCategory = nil
                }) {
                    Text("Tất cả phòng ban")
                        .font(.system(size: 11, weight: taskManager.selectedCategory == nil ? .bold : .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(taskManager.selectedCategory == nil ? Color(red: 0.1, green: 0.12, blue: 0.15) : Color.white)
                        .foregroundColor(taskManager.selectedCategory == nil ? .white : Color(red: 0.45, green: 0.48, blue: 0.54))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(taskManager.selectedCategory == nil ? 0.1 : 0.03), radius: 4, x: 0, y: 2)
                }

                ForEach(TaskCategory.allCases) { cat in
                    Button(action: {
                        if taskManager.selectedCategory == cat {
                            taskManager.selectedCategory = nil
                        } else {
                            taskManager.selectedCategory = cat
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 10))
                            Text(cat.rawValue)
                                .font(.system(size: 11, weight: taskManager.selectedCategory == cat ? .bold : .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(taskManager.selectedCategory == cat ? cat.color : Color.white)
                        .foregroundColor(taskManager.selectedCategory == cat ? .white : Color(red: 0.45, green: 0.48, blue: 0.54))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(taskManager.selectedCategory == cat ? 0.15 : 0.03), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 52))
                .foregroundColor(Color.orange.opacity(0.4))

            Text("Chưa có đầu việc nào")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.15, green: 0.18, blue: 0.22))

            Text("Bấm nút màu cam bên dưới để ghi âm giọng nói hoặc gõ tay công việc mới.")
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.5, green: 0.53, blue: 0.58))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                showingNewTaskSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                    Text("Tạo nhiệm vụ đầu tiên")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.orange)
            }
            .padding(.top, 4)

            Spacer()
        }
    }
}
