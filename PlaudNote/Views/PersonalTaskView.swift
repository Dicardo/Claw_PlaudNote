//
//  PersonalTaskView.swift
//  PlaudNote
//
//  个人任务面板 - 显示某个人的所有任务
//

import SwiftUI

struct PersonalTaskView: View {
    let assignee: String
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedStatus: TaskStatus? = nil
    @State private var showAddTaskSheet = false
    
    // 该负责人的所有任务
    var allTasks: [Task] {
        taskStore.getTasks(forAssignee: assignee)
    }
    
    // 过滤后的任务
    var filteredTasks: [Task] {
        if let status = selectedStatus {
            return allTasks.filter { $0.status == status }
        }
        return allTasks
    }
    
    // 按状态分组
    var groupedByStatus: [(status: TaskStatus, tasks: [Task])] {
        let grouped = Dictionary(grouping: filteredTasks) { $0.status }
        return TaskStatus.allCases.compactMap { status in
            if let tasks = grouped[status], !tasks.isEmpty {
                return (status: status, tasks: tasks)
            }
            return nil
        }
    }
    
    // 统计
    var statistics: (todo: Int, inProgress: Int, completed: Int) {
        let todo = allTasks.filter { $0.status == .todo }.count
        let inProgress = allTasks.filter { $0.status == .inProgress }.count
        let completed = allTasks.filter { $0.status == .completed }.count
        return (todo, inProgress, completed)
    }
    
    var completionRate: Double {
        guard !allTasks.isEmpty else { return 0 }
        return Double(statistics.completed) / Double(allTasks.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 个人资料卡片
                ProfileCard(
                    assignee: assignee,
                    totalTasks: allTasks.count,
                    completionRate: completionRate,
                    statistics: statistics
                )
                .padding(.horizontal)
                
                // 状态过滤
                StatusFilterView(selectedStatus: $selectedStatus)
                    .padding(.horizontal)
                
                // 任务列表
                if filteredTasks.isEmpty {
                    EmptyPersonalTaskView(assignee: assignee)
                } else {
                    PersonalTaskList(groupedByStatus: groupedByStatus)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(assignee)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddTaskSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTaskSheet) {
            // 这里可以添加新建任务的视图
            Text("新建任务")
        }
    }
}

// MARK: - 个人资料卡片
struct ProfileCard: View {
    let assignee: String
    let totalTasks: Int
    let completionRate: Double
    let statistics: (todo: Int, inProgress: Int, completed: Int)
    
    var body: some View {
        VStack(spacing: 16) {
            // 头像和姓名
            HStack(spacing: 16) {
                // 头像
                ZStack {
                    Circle()
                        .fill(avatarColor)
                        .frame(width: 64, height: 64)
                    
                    Text(String(assignee.prefix(1)))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(assignee)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(totalTasks) 项任务")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // 完成率进度条
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("完成进度")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(completionRate * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(progressColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * CGFloat(completionRate), height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // 统计数字
            HStack(spacing: 0) {
                PersonalStatItem(count: statistics.todo, label: "待办", color: .gray)
                Divider()
                PersonalStatItem(count: statistics.inProgress, label: "进行中", color: .blue)
                Divider()
                PersonalStatItem(count: statistics.completed, label: "已完成", color: .green)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var avatarColor: Color {
        // 根据名字生成固定的颜色
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .teal, .indigo]
        let hash = abs(assignee.hashValue)
        return colors[hash % colors.count]
    }
    
    private var progressColor: Color {
        if completionRate >= 0.8 {
            return .green
        } else if completionRate >= 0.5 {
            return .blue
        } else {
            return .orange
        }
    }
}

// MARK: - 个人统计项
struct PersonalStatItem: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 状态过滤视图
struct StatusFilterView: View {
    @Binding var selectedStatus: TaskStatus?
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(TaskStatus.allCases, id: \.self) { status in
                StatusButton(
                    status: status,
                    isSelected: selectedStatus == status
                ) {
                    if selectedStatus == status {
                        selectedStatus = nil
                    } else {
                        selectedStatus = status
                    }
                }
            }
        }
    }
}

// MARK: - 状态按钮
struct StatusButton: View {
    let status: TaskStatus
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: status.iconName)
                Text(status.displayName)
            }
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? statusColor.opacity(0.2) : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(isSelected ? statusColor : .primary)
            .cornerRadius(8)
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .todo:
            return .gray
        case .inProgress:
            return .blue
        case .completed:
            return .green
        }
    }
}

// MARK: - 个人任务列表
struct PersonalTaskList: View {
    let groupedByStatus: [(status: TaskStatus, tasks: [Task])]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(groupedByStatus, id: \.status) { group in
                StatusSection(status: group.status, tasks: group.tasks)
            }
        }
    }
}

// MARK: - 状态分区
struct StatusSection: View {
    let status: TaskStatus
    let tasks: [Task]
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 状态标题
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Image(systemName: status.iconName)
                        .foregroundColor(statusColor)
                    
                    Text(status.displayName)
                        .font(.headline)
                    
                    Text("(\(tasks.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            .foregroundColor(.primary)
            
            // 任务列表
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(tasks) { task in
                        PersonalTaskRow(task: task)
                        
                        if task.id != tasks.last?.id {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .todo:
            return .gray
        case .inProgress:
            return .blue
        case .completed:
            return .green
        }
    }
}

// MARK: - 个人任务行
struct PersonalTaskRow: View {
    @EnvironmentObject var taskStore: TaskStore
    let task: Task
    @State private var showEditSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态切换按钮
            Button(action: {
                taskStore.toggleTaskStatus(id: task.id)
            }) {
                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundColor(statusColor)
            }
            
            // 任务内容
            VStack(alignment: .leading, spacing: 4) {
                Text(task.content)
                    .font(.body)
                    .lineLimit(2)
                    .strikethrough(task.status == .completed)
                    .foregroundColor(task.status == .completed ? .secondary : .primary)
                
                if task.isUserModified {
                    HStack {
                        Image(systemName: "pencil")
                            .font(.caption2)
                        Text("已编辑")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // 编辑按钮
            Button(action: { showEditSheet = true }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showEditSheet) {
            TaskEditView(task: task)
                .environmentObject(taskStore)
        }
    }
    
    private var statusIcon: String {
        switch task.status {
        case .todo:
            return "circle"
        case .inProgress:
            return "circle.dashed"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch task.status {
        case .todo:
            return .gray
        case .inProgress:
            return .blue
        case .completed:
            return .green
        }
    }
}

// MARK: - 空任务视图
struct EmptyPersonalTaskView: View {
    let assignee: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("\(assignee) 暂无任务")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("该负责人目前没有分配任务")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }
}

#Preview {
    NavigationView {
        PersonalTaskView(assignee: "张三")
            .environmentObject(TaskStore())
    }
}
