//
//  MeetingSummaryView.swift
//  PlaudNote
//
//  会议总结视图 - 显示要点和关联任务
//

import SwiftUI

struct MeetingSummaryDetailView: View {
    let summary: MeetingSummary
    @EnvironmentObject var taskStore: TaskStore
    @State private var showEditSheet = false
    @State private var isGenerating = false
    
    // 关联的任务
    var linkedTasks: [Task] {
        summary.actionItemIds.compactMap { taskStore.getTask(by: $0) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 总结卡片
                SummaryCard(summary: summary)
                
                // 关键要点
                KeyPointsCard(keyPoints: summary.keyPoints)
                
                // 关联任务
                if !linkedTasks.isEmpty {
                    LinkedTasksCard(tasks: linkedTasks)
                }
                
                // 元信息
                MetaInfoCard(summary: summary)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("会议纪要")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEditSheet = true }) {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            MeetingSummaryEditView(summary: summary)
                .environmentObject(taskStore)
        }
    }
}

// MARK: - 总结卡片
struct SummaryCard: View {
    let summary: MeetingSummary
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("会议总结")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = summary.summary
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.accentColor)
                }
            }
            
            Divider()
            
            Text(summary.summary)
                .font(.body)
                .lineSpacing(4)
                .lineLimit(isExpanded ? nil : 5)
            
            if summary.summary.count > 200 {
                Button(action: { isExpanded.toggle() }) {
                    Text(isExpanded ? "收起" : "展开更多")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - 关键要点卡片
struct KeyPointsCard: View {
    let keyPoints: [String]
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                Text("关键要点")
                    .font(.headline)
                
                Spacer()
                
                Text("\(keyPoints.count) 项")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(8)
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(keyPoints.enumerated()), id: \.offset) { index, point in
                        KeyPointRow(index: index + 1, point: point)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - 要点行
struct KeyPointRow: View {
    let index: Int
    let point: String
    @State private var isCompleted = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 序号
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.accentColor)
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundColor(.white)
                } else {
                    Text("\(index)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // 内容
            Text(point)
                .font(.body)
                .lineSpacing(4)
                .strikethrough(isCompleted)
                .foregroundColor(isCompleted ? .secondary : .primary)
            
            Spacer()
            
            // 完成按钮
            Button(action: { isCompleted.toggle() }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .secondary)
            }
        }
    }
}

// MARK: - 关联任务卡片
struct LinkedTasksCard: View {
    let tasks: [Task]
    @EnvironmentObject var taskStore: TaskStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .font(.title3)
                    .foregroundColor(.purple)
                
                Text("关联任务")
                    .font(.headline)
                
                Spacer()
                
                Text("\(tasks.count) 项")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(8)
            }
            
            Divider()
            
            VStack(spacing: 8) {
                ForEach(tasks) { task in
                    LinkedTaskRow(task: task)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - 关联任务行
struct LinkedTaskRow: View {
    @EnvironmentObject var taskStore: TaskStore
    let task: Task
    
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
                    .lineLimit(1)
                    .strikethrough(task.status == .completed)
                    .foregroundColor(task.status == .completed ? .secondary : .primary)
                
                Text(task.assignee)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 状态标签
            Text(task.status.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.15))
                .foregroundColor(statusColor)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
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

// MARK: - 元信息卡片
struct MetaInfoCard: View {
    let summary: MeetingSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("信息")
                    .font(.headline)
            }
            
            Divider()
            
            HStack {
                Text("创建时间")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formattedDate(summary.createdAt))
                    .font(.subheadline)
            }
            
            HStack {
                Text("最后更新")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formattedDate(summary.updatedAt))
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 会议纪要编辑视图
struct MeetingSummaryEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taskStore: TaskStore
    let summary: MeetingSummary
    
    @State private var editedSummary: String
    @State private var editedKeyPoints: [String]
    @State private var newPoint: String = ""
    
    init(summary: MeetingSummary) {
        self.summary = summary
        _editedSummary = State(initialValue: summary.summary)
        _editedKeyPoints = State(initialValue: summary.keyPoints)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("会议总结")) {
                    TextEditor(text: $editedSummary)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("关键要点")) {
                    ForEach(Array(editedKeyPoints.enumerated()), id: \.offset) { index, point in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundColor(.secondary)
                            TextField("要点内容", text: $editedKeyPoints[index])
                        }
                    }
                    .onDelete(perform: deleteKeyPoint)
                    
                    HStack {
                        TextField("添加新要点", text: $newPoint)
                        Button(action: addKeyPoint) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                        .disabled(newPoint.isEmpty)
                    }
                }
            }
            .navigationTitle("编辑纪要")
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
                }
            }
        }
    }
    
    private func deleteKeyPoint(at offsets: IndexSet) {
        editedKeyPoints.remove(atOffsets: offsets)
    }
    
    private func addKeyPoint() {
        guard !newPoint.isEmpty else { return }
        editedKeyPoints.append(newPoint)
        newPoint = ""
    }
    
    private func saveChanges() {
        var updatedSummary = summary
        updatedSummary.updateSummary(editedSummary)
        updatedSummary.updateKeyPoints(editedKeyPoints)
        taskStore.updateMeetingSummary(updatedSummary)
        dismiss()
    }
}

// MARK: - 空会议纪要视图
struct EmptyMeetingSummaryView: View {
    let recording: Recording
    @StateObject private var summaryService = MeetingSummaryService()
    @State private var hasGenerated = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("暂无会议纪要")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击按钮生成会议纪要")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if summaryService.isGenerating {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding()
            } else {
                Button(action: generateSummary) {
                    Label("生成会议纪要", systemImage: "sparkles")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func generateSummary() {
        summaryService.generateSummary(from: recording.transcript, recordingId: recording.id) { _ in
            hasGenerated = true
        }
    }
}

#Preview {
    NavigationView {
        MeetingSummaryDetailView(summary: MeetingSummary.mock())
            .environmentObject(TaskStore())
    }
}
