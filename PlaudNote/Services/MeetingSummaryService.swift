//
//  MeetingSummaryService.swift
//  PlaudNote
//
//  会议纪要生成服务
//

import Foundation

class MeetingSummaryService: ObservableObject {
    
    @Published var isGenerating = false
    @Published var meetingSummary: MeetingSummary?
    @Published var errorMessage: String?
    
    // MARK: - 会议纪要生成
    
    /// 生成会议纪要
    /// - Parameters:
    ///   - transcript: 转录文本
    ///   - recordingId: 关联的录音ID
    ///   - completion: 完成回调
    func generateSummary(from transcript: String, recordingId: UUID, completion: @escaping (MeetingSummary?) -> Void) {
        isGenerating = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let summary = self?.performGeneration(from: transcript, recordingId: recordingId)
            
            DispatchQueue.main.async {
                self?.meetingSummary = summary
                self?.isGenerating = false
                completion(summary)
            }
        }
    }
    
    /// 执行纪要生成
    private func performGeneration(from transcript: String, recordingId: UUID) -> MeetingSummary {
        // 提取关键要点
        let keyPoints = extractKeyPoints(from: transcript)
        
        // 生成总结文本
        let summary = generateSummaryText(from: transcript, keyPoints: keyPoints)
        
        return MeetingSummary(
            recordingId: recordingId,
            keyPoints: keyPoints,
            summary: summary,
            actionItemIds: []
        )
    }
    
    /// 提取关键要点
    private func extractKeyPoints(from transcript: String) -> [String] {
        var keyPoints: [String] = []
        let lines = transcript.components(separatedBy: .newlines)
        
        // 关键信息指示词
        let importanceIndicators = [
            "重要", "关键", "主要", "重点", "核心",
            "决定", "确定", "确认", "通过", "同意",
            "问题", "风险", "挑战", "困难",
            "目标", "计划", "方案", "策略",
            "结论", "总结", "结果", "成果",
            "下一步", "后续", "接下来", "之后",
            "important", "key", "main", "critical",
            "decided", "confirmed", "agreed",
            "goal", "plan", "strategy",
            "conclusion", "result",
            "next", "follow-up"
        ]
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }
            
            // 检查是否包含重要指示词
            let isImportant = importanceIndicators.contains { indicator in
                trimmedLine.contains(indicator)
            }
            
            // 检查是否是列表项（以数字或符号开头）
            let isListItem = trimmedLine.range(of: "^[0-9一二三四五六七八九十]+[.、.．\\s]", options: .regularExpression) != nil ||
                            trimmedLine.hasPrefix("-") ||
                            trimmedLine.hasPrefix("•") ||
                            trimmedLine.hasPrefix("*")
            
            if isImportant || isListItem {
                let cleanedPoint = cleanKeyPoint(trimmedLine)
                if cleanedPoint.count >= 5 && !keyPoints.contains(cleanedPoint) {
                    keyPoints.append(cleanedPoint)
                }
            }
        }
        
        // 限制要点数量
        return Array(keyPoints.prefix(8))
    }
    
    /// 清理要点文本
    private func cleanKeyPoint(_ point: String) -> String {
        var cleaned = point
        
        // 移除列表标记
        cleaned = cleaned.replacingOccurrences(of: "^[0-9一二三四五六七八九十]+[.、.．\\s-\\*•]+\\s*", with: "", options: .regularExpression)
        
        // 移除开头的中文序号
        cleaned = cleaned.replacingOccurrences(of: "^第[一二三四五六七八九十]+[点条项]\\s*", with: "", options: .regularExpression)
        
        // 移除多余空格
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 限制长度
        if cleaned.count > 100 {
            cleaned = String(cleaned.prefix(100)) + "..."
        }
        
        return cleaned
    }
    
    /// 生成总结文本
    private func generateSummaryText(from transcript: String, keyPoints: [String]) -> String {
        // 分析会议主题
        let topic = extractTopic(from: transcript)
        
        // 分析会议类型
        let meetingType = analyzeMeetingType(from: transcript)
        
        // 构建总结
        var summaryParts: [String] = []
        
        // 开头
        summaryParts.append("本次\(meetingType)主要\(topic)，")
        
        // 根据要点数量生成总结
        if keyPoints.isEmpty {
            summaryParts.append("讨论了相关事项。")
        } else if keyPoints.count <= 3 {
            summaryParts.append("重点包括：")
            summaryParts.append(keyPoints.joined(separator: "；"))
            summaryParts.append("。")
        } else {
            summaryParts.append("涵盖了多个方面：")
            
            // 分类要点
            let categories = categorizePoints(keyPoints)
            
            if categories.isEmpty {
                summaryParts.append(keyPoints.prefix(4).joined(separator: "；"))
            } else {
                for (category, points) in categories {
                    if !points.isEmpty {
                        summaryParts.append("\(category)：\(points.joined(separator: "、"))；")
                    }
                }
            }
            
            summaryParts.append("。")
        }
        
        // 添加后续行动提示
        summaryParts.append("后续将按照讨论结果推进相关工作。")
        
        return summaryParts.joined()
    }
    
    /// 提取会议主题
    private func extractTopic(from transcript: String) -> String {
        let topicKeywords = [
            "讨论": "讨论了",
            "研究": "研究了",
            "汇报": "听取了汇报",
            "评审": "进行了评审",
            "规划": "进行了规划",
            "总结": "进行了总结",
            "部署": "进行了部署",
            "安排": "进行了安排"
        ]
        
        for (keyword, description) in topicKeywords {
            if transcript.contains(keyword) {
                return description
            }
        }
        
        return "讨论了相关工作"
    }
    
    /// 分析会议类型
    private func analyzeMeetingType(from transcript: String) -> String {
        let meetingTypes = [
            ("周会", "周例会"),
            ("例会", "例会"),
            ("晨会", "晨会"),
            ("夕会", "夕会"),
            ("评审", "评审会"),
            ("规划", "规划会"),
            ("总结", "总结会"),
            ("启动", "启动会"),
            ("复盘", "复盘会"),
            ("同步", "同步会"),
            ("站会", "站会"),
            ("产品", "产品会议"),
            ("技术", "技术会议"),
            ("设计", "设计评审"),
            ("需求", "需求评审")
        ]
        
        for (keyword, type) in meetingTypes {
            if transcript.contains(keyword) {
                return type
            }
        }
        
        return "会议"
    }
    
    /// 分类要点
    private func categorizePoints(_ points: [String]) -> [String: [String]] {
        var categories: [String: [String]] = [:]
        
        let categoryKeywords: [String: [String]] = [
            "决策": ["决定", "确定", "确认", "通过", "同意", "选择"],
            "问题": ["问题", "风险", "挑战", "困难", "障碍", "bug", "issue"],
            "计划": ["目标", "计划", "方案", "策略", "路线图", "时间表"],
            "执行": ["完成", "处理", "解决", "实施", "执行", "推进"]
        ]
        
        for point in points {
            var categorized = false
            
            for (category, keywords) in categoryKeywords {
                if keywords.contains(where: { point.contains($0) }) {
                    categories[category, default: []].append(point)
                    categorized = true
                    break
                }
            }
            
            if !categorized {
                categories["其他", default: []].append(point)
            }
        }
        
        return categories
    }
}

// MARK: - 扩展：智能摘要
extension MeetingSummaryService {
    
    /// 生成智能摘要（模拟AI生成）
    func generateSmartSummary(from transcript: String, recordingId: UUID, completion: @escaping (MeetingSummary?) -> Void) {
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 模拟AI处理延迟
            Thread.sleep(forTimeInterval: 2.0)
            
            let summary = self?.performSmartGeneration(from: transcript, recordingId: recordingId)
            
            DispatchQueue.main.async {
                self?.meetingSummary = summary
                self?.isGenerating = false
                completion(summary)
            }
        }
    }
    
    /// 执行智能生成
    private func performSmartGeneration(from transcript: String, recordingId: UUID) -> MeetingSummary {
        // 使用更复杂的逻辑生成摘要
        let keyPoints = extractKeyPoints(from: transcript)
        let enhancedPoints = enhanceKeyPoints(keyPoints)
        let summary = generateEnhancedSummary(from: transcript, keyPoints: enhancedPoints)
        
        return MeetingSummary(
            recordingId: recordingId,
            keyPoints: enhancedPoints,
            summary: summary,
            actionItemIds: []
        )
    }
    
    /// 增强要点
    private func enhanceKeyPoints(_ points: [String]) -> [String] {
        return points.map { point in
            // 添加更多上下文信息
            if point.count < 20 {
                return point + "（需要重点关注）"
            }
            return point
        }
    }
    
    /// 生成增强型总结
    private func generateEnhancedSummary(from transcript: String, keyPoints: [String]) -> String {
        // 生成更详细的总结
        let baseSummary = generateSummaryText(from: transcript, keyPoints: keyPoints)
        
        // 添加时间信息
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM月dd日"
        let dateStr = dateFormatter.string(from: Date())
        
        return "【\(dateStr)会议摘要】\n\n\(baseSummary)"
    }
}
