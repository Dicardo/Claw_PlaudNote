//
//  MeetingSummary.swift
//  PlaudNote
//
//  会议纪要数据模型
//

import Foundation

// MARK: - 会议纪要模型
struct MeetingSummary: Identifiable, Codable, Equatable {
    let id: UUID
    let recordingId: UUID        // 关联的录音ID
    var keyPoints: [String]      // 会议要点数组
    var summary: String          // 总结文本
    var actionItemIds: [UUID]    // 关联的任务ID数组
    var createdAt: Date          // 创建时间
    var updatedAt: Date          // 更新时间
    
    init(
        id: UUID = UUID(),
        recordingId: UUID,
        keyPoints: [String] = [],
        summary: String = "",
        actionItemIds: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.recordingId = recordingId
        self.keyPoints = keyPoints
        self.summary = summary
        self.actionItemIds = actionItemIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // 更新会议要点
    mutating func updateKeyPoints(_ newKeyPoints: [String]) {
        self.keyPoints = newKeyPoints
        self.updatedAt = Date()
    }
    
    // 更新总结文本
    mutating func updateSummary(_ newSummary: String) {
        self.summary = newSummary
        self.updatedAt = Date()
    }
    
    // 添加关联任务
    mutating func addActionItem(_ taskId: UUID) {
        if !actionItemIds.contains(taskId) {
            self.actionItemIds.append(taskId)
            self.updatedAt = Date()
        }
    }
    
    // 移除关联任务
    mutating func removeActionItem(_ taskId: UUID) {
        self.actionItemIds.removeAll { $0 == taskId }
        self.updatedAt = Date()
    }
}

// MARK: - Mock Data for Preview
extension MeetingSummary {
    static func mock(recordingId: UUID = UUID()) -> MeetingSummary {
        MeetingSummary(
            id: UUID(),
            recordingId: recordingId,
            keyPoints: [
                "确定了Q4产品路线图",
                "讨论了用户体验优化方案",
                "确定了技术架构升级计划"
            ],
            summary: "本次会议主要讨论了Q4季度的产品规划和技术升级方案。团队一致同意优先优化用户体验，并制定了详细的实施计划。",
            actionItemIds: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
