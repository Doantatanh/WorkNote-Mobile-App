import SwiftUI
import UIKit

public struct MainTaskListView: View {
    @StateObject private var taskManager = TaskManager()
    @StateObject private var player = AudioPlayerService()

    @State private var showingNewTaskSheet = false
    @State private var selectedTaskForDetail: TaskItem?

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // Enterprise Workspace & KPI Dashboard Header
                    dashboardHeaderView
                        .padding(.horizontal)
                        .padding(.top, 6)
                        .padding(.bottom, 10)

                    // Filter segmented control
                    Picker("Trạng thái", selection: $taskManager.selectedFilter) {
                        ForEach(TaskFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    // Department / Category Horizontal Filter
                    categoryFilterScrollView
                        .padding(.bottom, 6)

                    // Task List or Empty View
                    if taskManager.filteredTasks.isEmpty {
                        emptyStateView
                    } else {
                        List {
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
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        taskManager.deleteTask(task)
                                    } label: {
                                        Label("Xóa", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        taskManager.toggleTask(id: task.id)
                                    } label: {
                                        Label(
                                            task.isCompleted ? "Chưa xong" : "Hoàn thành",
                                            systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                        )
                                    }
                                    .tint(task.isCompleted ? .orange : .green)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .searchable(text: $taskManager.searchQuery, prompt: "Tìm theo mã (ENT), tiêu đề, người phụ trách...")
                    }
                }

                // Executive Floating Action Button
                Button(action: {
                    showingNewTaskSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("Ghi âm / Thêm việc")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color(red: 0.92, green: 0.38, blue: 0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(24)
                    .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                }
                .padding(.trailing, 18)
                .padding(.bottom, 18)
            }
            .navigationTitle("WorkNote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("HQ Workspace")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showingNewTaskSheet) {
                NewTaskSheet(taskManager: taskManager)
            }
            .sheet(item: $selectedTaskForDetail) { task in
                TaskDetailView(task: task, taskManager: taskManager, player: player)
            }
        }
    }

    // MARK: - Enterprise KPI Dashboard
    private var dashboardHeaderView: some View {
        VStack(spacing: 10) {
            // Stats Row
            HStack(spacing: 8) {
                enterpriseKpiCard(
                    title: "Tổng nhiệm vụ",
                    count: "\(taskManager.totalCount)",
                    subtitle: "Đầu việc hoạt động",
                    color: Color.primary
                )

                enterpriseKpiCard(
                    title: "Chờ xử lý (SLA)",
                    count: "\(taskManager.pendingCount)",
                    subtitle: "Cần xử lý gấp",
                    color: Color.orange
                )

                enterpriseKpiCard(
                    title: "Đã hoàn thành",
                    count: "\(taskManager.completedCount)",
                    subtitle: "\(Int(taskManager.progressPercentage * 100))% đạt chỉ tiêu",
                    color: Color.green
                )
            }

            // Enterprise SLA Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Tỷ lệ tuân thủ hạn chót (SLA Compliance)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(taskManager.progressPercentage * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 5)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(taskManager.progressPercentage), height: 5)
                            .animation(.spring(), value: taskManager.progressPercentage)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.7))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }

    private func enterpriseKpiCard(title: String, count: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text(count)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(color)

            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.8))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.tertiarySystemBackground).opacity(0.6))
        .cornerRadius(8)
    }

    // MARK: - Department / Category Filter Bar
    private var categoryFilterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Button(action: {
                    taskManager.selectedCategory = nil
                }) {
                    Text("Tất cả phòng ban")
                        .font(.system(size: 11, weight: taskManager.selectedCategory == nil ? .bold : .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(taskManager.selectedCategory == nil ? Color.primary : Color(.secondarySystemBackground))
                        .foregroundColor(taskManager.selectedCategory == nil ? Color(.systemBackground) : .secondary)
                        .cornerRadius(6)
                }

                ForEach(TaskCategory.allCases) { cat in
                    Button(action: {
                        if taskManager.selectedCategory == cat {
                            taskManager.selectedCategory = nil
                        } else {
                            taskManager.selectedCategory = cat
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 9))
                            Text(cat.rawValue)
                                .font(.system(size: 11, weight: taskManager.selectedCategory == cat ? .bold : .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(taskManager.selectedCategory == cat ? cat.color : Color(.secondarySystemBackground))
                        .foregroundColor(taskManager.selectedCategory == cat ? .white : .secondary)
                        .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Không có đầu việc nào")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            Text("Tất cả công việc trong bộ lọc này đã được hoàn thành hoặc chưa có phát sinh mới.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button(action: {
                showingNewTaskSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Thêm nhiệm vụ mới")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.blue)
            }
            .padding(.top, 4)

            Spacer()
        }
    }
}
