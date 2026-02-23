//
//  Task.swift
//  PlaudNote
//
//  任务数据模型
//

import Foundation

// MARK: - 任务状态
enum TaskStatus: String, Codable, CaseIterable {
    case todo = "待办"
    case inProgress = "进行中"
    case completed = "已完成"
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .todo:
            return "circle"
        case .inProgress:
            return "circle.dashed"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
    
    var colorName: String {
        switch self {
        case .todo:
            return "gray"
        case .inProgress:
            return "blue"
        case .completed:
            return "green"
        }
    }
}

// MARK: - 任务模型
struct Task: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String          // 任务内容
    var assignee: String         // 负责人
    var status: TaskStatus       // 任务状态
    let sourceRecordingId: UUID  // 来源录音ID
    var createdAt: Date          // 创建时间
    var updatedAt: Date          // 更新时间
    var isUserModified: Bool     // 是否被用户修改过
    
    init(
        id: UUID = UUID(),
        content: String,
        assignee: String,
        status: TaskStatus = .todo,
        sourceRecordingId: UUID,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isUserModified: Bool = false
    ) {
        self.id = id
        self.content = content
        self.assignee = assignee
        self.status = status
        self.sourceRecordingId = sourceRecordingId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isUserModified = isUserModified
    }
    
    // 更新任务状态
    mutating func updateStatus(_ newStatus: TaskStatus) {
        self.status = newStatus
        self.updatedAt = Date()
    }
    
    // 更新任务内容
    mutating func updateContent(_ newContent: String) {
        self.content = newContent
        self.isUserModified = true
        self.updatedAt = Date()
    }
    
    // 更新负责人
    mutating func updateAssignee(_ newAssignee: String) {
        self.assignee = newAssignee
        self.isUserModified = true
        self.updatedAt = Date()
    }
}

// MARK: - Mock Data for Preview
extension Task {
    static func mock(recordingId: UUID = UUID()) -> Task {
        Task(
            id: UUID(),
            content: "完成产品需求文档",
            assignee: "张三",
            status: .todo,
            sourceRecordingId: recordingId,
            createdAt: Date(),
            updatedAt: Date(),
            isUserModified: false
        )
    }
    
    static func mockList(recordingId: UUID = UUID()) -> [Task] {
        [
            Task(
                id: UUID(),
                content: "完成产品需求文档",
                assignee: "张三",
                status: .todo,
                sourceRecordingId: recordingId
            ),
            Task(
                id: UUID(),
                content: "设计新版UI界面",
                assignee: "李四",
                status: .inProgress,
                sourceRecordingId: recordingId
            ),
            Task(
                id: UUID(),
                content: "修复登录页面bug",
                assignee: "王五",
                status: .completed,
                sourceRecordingId: recordingId
            ),
            Task(
                id: UUID(),
                content: "编写API接口文档",
                assignee: "张三",
                status: .todo,
                sourceRecordingId: recordingId
            )
        ]
    }
}
