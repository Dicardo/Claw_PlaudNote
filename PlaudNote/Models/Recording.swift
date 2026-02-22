//
//  Recording.swift
//  PlaudNote
//
//  录音数据模型
//

import Foundation

struct Recording: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    let audioFileURL: URL
    let createdAt: Date
    let duration: TimeInterval
    var transcript: String
    var isTranscribed: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        audioFileURL: URL,
        createdAt: Date = Date(),
        duration: TimeInterval,
        transcript: String = "",
        isTranscribed: Bool = false
    ) {
        self.id = id
        self.title = title
        self.audioFileURL = audioFileURL
        self.createdAt = createdAt
        self.duration = duration
        self.transcript = transcript
        self.isTranscribed = isTranscribed
    }
    
    // 格式化时长
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // 格式化日期
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Mock Data for Preview
extension Recording {
    static func mock() -> Recording {
        Recording(
            id: UUID(),
            title: "团队周会",
            audioFileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
            createdAt: Date(),
            duration: 1865,
            transcript: "今天我们讨论了下个季度的产品规划。主要目标包括：1. 提升用户体验；2. 增加新功能模块；3. 优化性能。",
            isTranscribed: true
        )
    }
}
