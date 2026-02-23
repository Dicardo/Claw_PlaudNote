//
//  TaskBoardView.swift
//  PlaudNote
//
//  总任务面板 - 显示所有任务，按负责人分组
//

import SwiftUI

struct TaskBoardView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var selectedAssignee: String? = nil
    @State private var searchText = ""
    @State private var showFilterSheet = false
    @State private var selectedStatus: TaskStatus? = nil
    
    // 过滤后的任务
    var filteredTasks: [Task] {
        var tasks = taskStore.tasks
        
        // 搜索过滤
        if !searchText.isEmpty {
            tasks = tasks.filter {
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                $0.assignee.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 状态过滤
        if let status = selectedStatus {
            tasks = tasks.filter { $0.status == status }
        }
        
        return tasks.sorted { $0.createdAt > $1.createdAt }
    }
    
    // 按负责人分组
    var groupedTasks: [(assignee: String, tasks: [Task])] {
        let grouped = Dictionary(grouping: filteredTasks) { $0.assignee }
        return grouped.map { (assignee: $0.key, tasks: $0.value) }
            .sorted { $0.assignee < $1.assignee }
    }
    
    // 统计信息
    var statistics: (total: Int, todo: Int, inProgress: Int, completed: Int) {
        taskStore.getTaskStatistics()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 统计卡片
                    StatisticsCard(statistics: statistics)
                        .padding(.horizontal)
                    
                    // 搜索栏
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    // 过滤按钮
                    FilterBar(selectedStatus: $selectedStatus)
                        .padding(.horizontal)
                    
                    // 任务列表
                    if filteredTasks.isEmpty {
                        EmptyTaskView()
                    } else {
                        TaskListView(groupedTasks: groupedTasks)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("任务面板")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: PersonalTaskListView()) {
                        Image(systemName: "person.2")
                    }
                }
            }
        }
    }
}

// MARK: - 统计卡片
struct StatisticsCard: View {
    let statistics: (total: Int, todo: Int, inProgress: Int, completed: Int)
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("任务统计")
                    .font(.headline)
                Spacer()
                Text("共 \(statistics.total) 项")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                StatItem(count: statistics.todo, label: "待办", color: .gray)
                StatItem(count: statistics.inProgress, label: "进行中", color: .blue)
                StatItem(count: statistics.completed, label: "已完成", color: .green)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - 统计项
struct StatItem: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 过滤栏
struct FilterBar: View {
    @Binding var selectedStatus: TaskStatus?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "全部",
                    isSelected: selectedStatus == nil,
                    color: .primary
                ) {
                    selectedStatus = nil
                }
                
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    FilterChip(
                        title: status.displayName,
                        isSelected: selectedStatus == status,
                        color: statusColor(status)
                    ) {
                        selectedStatus = status
                    }
                }
            }
        }
    }
    
    private func statusColor(_ status: TaskStatus) -> Color {
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

// MARK: - 过滤芯片
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color.opacity(0.2) : Color(.tertiarySystemGroupedBackground))
                .foregroundColor(isSelected ? color : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - 任务列表视图
struct TaskListView: View {
    let groupedTasks: [(assignee: String, tasks: [Task])]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(groupedTasks, id: \.assignee) { group in
                AssigneeSection(assignee: group.assignee, tasks: group.tasks)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 负责人分区
struct AssigneeSection: View {
    let assignee: String
    let tasks: [Task]
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 负责人标题
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text(assignee)
                        .font(.headline)
                    
                    Text("(\(tasks.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    NavigationLink(destination: PersonalTaskView(assignee: assignee)) {
                        Text("查看全部")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 任务列表
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(tasks.prefix(5)) { task in
                        TaskRowView(task: task)
                    }
                    
                    if tasks.count > 5 {
                        NavigationLink(destination: PersonalTaskView(assignee: assignee)) {
                            Text("还有 \(tasks.count - 5) 项任务...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - 任务行视图
struct TaskRowView: View {
    @EnvironmentObject var taskStore: TaskStore
    let task: Task
    @State private var showEditSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态图标
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
                
                HStack(spacing: 8) {
                    Text(task.assignee)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if task.isUserModified {
                        Image(systemName: "pencil")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
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
struct EmptyTaskView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("暂无任务")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("在录音详情中生成任务后，将显示在这里")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}

// MARK: - 个人任务列表视图（导航用）
struct PersonalTaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    
    var assignees: [String] {
        taskStore.getAllAssignees()
    }
    
    var body: some View {
        List {
            ForEach(assignees, id: \.self) { assignee in
                NavigationLink(destination: PersonalTaskView(assignee: assignee)) {
                    HStack {
                        Image(systemName: "person.circle")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                        
                        Text(assignee)
                            .font(.body)
                        
                        Spacer()
                        
                        let count = taskStore.getTasks(forAssignee: assignee).count
                        Text("\(count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(10)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("负责人列表")
    }
}

#Preview {
    TaskBoardView()
        .environmentObject(TaskStore())
}
