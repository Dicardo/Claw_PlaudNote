//
//  TaskEditView.swift
//  PlaudNote
//
//  任务编辑视图 - 可修改任务内容和负责人
//

import SwiftUI

struct TaskEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taskStore: TaskStore
    let task: Task
    
    @State private var editedContent: String
    @State private var editedAssignee: String
    @State private var editedStatus: TaskStatus
    @State private var showDeleteConfirm = false
    
    // 常用负责人列表（可以从历史任务中动态获取）
    var commonAssignees: [String] {
        var assignees = taskStore.getAllAssignees()
        if !assignees.contains(editedAssignee) {
            assignees.append(editedAssignee)
        }
        return assignees.sorted()
    }
    
    init(task: Task) {
        self.task = task
        _editedContent = State(initialValue: task.content)
        _editedAssignee = State(initialValue: task.assignee)
        _editedStatus = State(initialValue: task.status)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 任务内容
                Section(header: Text("任务内容")) {
                    TextEditor(text: $editedContent)
                        .frame(minHeight: 80)
                }
                
                // 负责人
                Section(header: Text("负责人")) {
                    TextField("负责人姓名", text: $editedAssignee)
                    
                    if !commonAssignees.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(commonAssignees, id: \.self) { assignee in
                                    AssigneeChip(
                                        name: assignee,
                                        isSelected: editedAssignee == assignee
                                    ) {
                                        editedAssignee = assignee
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 任务状态
                Section(header: Text("任务状态")) {
                    Picker("状态", selection: $editedStatus) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            HStack {
                                Image(systemName: status.iconName)
                                Text(status.displayName)
                            }
                            .tag(status)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                // 元信息
                Section(header: Text("信息")) {
                    HStack {
                        Text("创建时间")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formattedDate(task.createdAt))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("最后更新")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formattedDate(task.updatedAt))
                            .foregroundColor(.secondary)
                    }
                    
                    if task.isUserModified {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(.orange)
                            Text("已被用户修改")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // 删除按钮
                Section {
                    Button(role: .destructive, action: { showDeleteConfirm = true }) {
                        HStack {
                            Spacer()
                            Label("删除任务", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(editedContent.isEmpty || editedAssignee.isEmpty)
                }
            }
            .confirmationDialog("确认删除", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("删除任务", role: .destructive) {
                    deleteTask()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("此操作无法撤销")
            }
        }
    }
    
    private func saveChanges() {
        var updatedTask = task
        
        // 更新内容（如果有变化）
        if editedContent != task.content {
            updatedTask.updateContent(editedContent)
        }
        
        // 更新负责人（如果有变化）
        if editedAssignee != task.assignee {
            updatedTask.updateAssignee(editedAssignee)
        }
        
        // 更新状态（如果有变化）
        if editedStatus != task.status {
            updatedTask.updateStatus(editedStatus)
        }
        
        taskStore.updateTask(updatedTask)
        dismiss()
    }
    
    private func deleteTask() {
        taskStore.deleteTask(task)
        dismiss()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 负责人芯片
struct AssigneeChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "person.circle")
                    .font(.caption)
                Text(name)
                    .font(.subheadline)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(isSelected ? .accentColor : .primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - 快速编辑视图（用于内联编辑）
struct TaskQuickEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taskStore: TaskStore
    let task: Task
    
    @State private var editedContent: String
    @State private var editedAssignee: String
    
    init(task: Task) {
        self.task = task
        _editedContent = State(initialValue: task.content)
        _editedAssignee = State(initialValue: task.assignee)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Text("编辑任务")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // 内容编辑
            VStack(alignment: .leading, spacing: 8) {
                Text("任务内容")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $editedContent)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            // 负责人编辑
            VStack(alignment: .leading, spacing: 8) {
                Text("负责人")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("负责人姓名", text: $editedAssignee)
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 16) {
                Button(action: { dismiss() }) {
                    Text("取消")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(12)
                }
                
                Button(action: saveChanges) {
                    Text("保存")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                }
                .disabled(editedContent.isEmpty || editedAssignee.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top)
    }
    
    private func saveChanges() {
        var updatedTask = task
        
        if editedContent != task.content {
            updatedTask.updateContent(editedContent)
        }
        
        if editedAssignee != task.assignee {
            updatedTask.updateAssignee(editedAssignee)
        }
        
        taskStore.updateTask(updatedTask)
        dismiss()
    }
}

// MARK: - 新建任务视图
struct NewTaskView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taskStore: TaskStore
    let recordingId: UUID
    let defaultAssignee: String?
    
    @State private var content: String = ""
    @State private var assignee: String = ""
    @State private var status: TaskStatus = .todo
    
    init(recordingId: UUID, defaultAssignee: String? = nil) {
        self.recordingId = recordingId
        self.defaultAssignee = defaultAssignee
        _assignee = State(initialValue: defaultAssignee ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务内容")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 80)
                }
                
                Section(header: Text("负责人")) {
                    TextField("负责人姓名", text: $assignee)
                    
                    // 常用负责人
                    let commonAssignees = taskStore.getAllAssignees()
                    if !commonAssignees.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(commonAssignees, id: \.self) { name in
                                    AssigneeChip(
                                        name: name,
                                        isSelected: assignee == name
                                    ) {
                                        assignee = name
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("初始状态")) {
                    Picker("状态", selection: $status) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            HStack {
                                Image(systemName: status.iconName)
                                Text(status.displayName)
                            }
                            .tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("新建任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        createTask()
                    }
                    .disabled(content.isEmpty || assignee.isEmpty)
                }
            }
        }
    }
    
    private func createTask() {
        let newTask = Task(
            content: content,
            assignee: assignee,
            status: status,
            sourceRecordingId: recordingId
        )
        taskStore.addTask(newTask)
        dismiss()
    }
}

#Preview {
    TaskEditView(task: Task.mock())
        .environmentObject(TaskStore())
}
