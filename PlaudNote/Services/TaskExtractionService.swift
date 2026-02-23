//
//  TaskExtractionService.swift
//  PlaudNote
//
//  任务提取服务 - 从转录文本中自动提取任务和负责人
//

import Foundation

class TaskExtractionService: ObservableObject {
    
    @Published var isExtracting = false
    @Published var extractedTasks: [Task] = []
    @Published var errorMessage: String?
    
    // MARK: - 任务提取
    
    /// 从转录文本中提取任务
    /// - Parameters:
    ///   - transcript: 转录文本
    ///   - recordingId: 关联的录音ID
    ///   - completion: 完成回调
    func extractTasks(from transcript: String, recordingId: UUID, completion: @escaping ([Task]) -> Void) {
        isExtracting = true
        errorMessage = nil
        
        // 模拟异步处理
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let tasks = self?.performExtraction(from: transcript, recordingId: recordingId) ?? []
            
            DispatchQueue.main.async {
                self?.extractedTasks = tasks
                self?.isExtracting = false
                completion(tasks)
            }
        }
    }
    
    /// 执行实际的任务提取（基于规则解析）
    private func performExtraction(from transcript: String, recordingId: UUID) -> [Task] {
        var tasks: [Task] = []
        let lines = transcript.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }
            
            // 尝试从当前行提取任务
            if let task = extractTaskFromLine(trimmedLine, recordingId: recordingId) {
                tasks.append(task)
            }
        }
        
        return tasks
    }
    
    /// 从单行文本中提取任务
    private func extractTaskFromLine(_ line: String, recordingId: UUID) -> Task? {
        // 任务关键词列表
        let taskKeywords = [
            "需要", "要", "必须", "应该", "得", "负责", "完成", "处理", "解决",
            "准备", "整理", "编写", "撰写", "制作", "设计", "开发", "测试",
            "review", "check", "prepare", "finish", "complete", "handle"
        ]
        
        // 负责人指示词
        let assigneeIndicators = [
            "由", "让", "叫", "请", "安排", "交给", "分配给",
            "by", "assign to", "let", "ask"
        ]
        
        // 检查是否包含任务关键词
        let containsTaskKeyword = taskKeywords.contains { keyword in
            line.contains(keyword)
        }
        
        // 如果不包含任务关键词，可能不是任务描述
        guard containsTaskKeyword else { return nil }
        
        // 提取负责人
        var assignee = "未指定"
        
        // 尝试匹配 "[某人]负责..." 或 "由[某人]..." 等模式
        for indicator in assigneeIndicators {
            if let extractedName = extractName(after: indicator, in: line) {
                assignee = extractedName
                break
            }
        }
        
        // 如果没有找到明确的负责人指示词，尝试匹配常见人名模式
        if assignee == "未指定" {
            assignee = extractPotentialName(from: line)
        }
        
        // 清理任务内容（移除负责人相关描述）
        let content = cleanTaskContent(line, assignee: assignee)
        
        return Task(
            content: content,
            assignee: assignee,
            status: .todo,
            sourceRecordingId: recordingId
        )
    }
    
    /// 在指定关键词后提取人名
    private func extractName(after indicator: String, in text: String) -> String? {
        guard let range = text.range(of: indicator) else { return nil }
        
        let afterIndicator = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        
        // 尝试提取人名（假设人名在关键词后，长度2-4个字符）
        let patterns = [
            "^([\u{4e00}-\u{9fff}]{2,4})",  // 中文名 2-4字
            "^([A-Za-z]+(?:\\s+[A-Za-z]+)?)"  // 英文名
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: afterIndicator, options: [], range: NSRange(location: 0, length: afterIndicator.utf16.count)) {
                if let nameRange = Range(match.range(at: 1), in: afterIndicator) {
                    let name = String(afterIndicator[nameRange])
                    // 过滤掉常见非人名词
                    let nonNameWords = ["大家", "我们", "你们", "他们", "所有人", "团队", "部门", "公司", "这个", "那个"]
                    if !nonNameWords.contains(name) {
                        return name
                    }
                }
            }
        }
        
        return nil
    }
    
    /// 从文本中提取可能的人名
    private func extractPotentialName(from text: String) -> String {
        // 常见中文姓氏
        let surnames = ["张", "王", "李", "刘", "陈", "杨", "黄", "赵", "吴", "周", "徐", "孙", "马", "朱", "胡", "郭", "何", "林", "罗", "高", "郑", "梁", "谢", "宋", "唐", "许", "韩", "冯", "邓", "曹", "彭", "曾", "肖", "田", "董", "袁", "潘", "于", "蒋", "蔡", "余", "杜", "叶", "程", "苏", "魏", "吕", "丁", "任", "沈", "姚", "卢", "姜", "崔", "钟", "谭", "陆", "汪", "范", "金", "石", "廖", "贾", "夏", "韦", "付", "方", "白", "邹", "孟", "熊", "秦", "邱", "江", "尹", "薛", "闫", "段", "雷", "侯", "龙", "史", "陶", "黎", "贺", "顾", "毛", "郝", "龚", "邵", "万", "钱", "严", "覃", "武", "戴", "莫", "孔", "白", "盛", "林", "翟", "倪", "康", "熊", "邢", "瞿", "纪", "舒", "屈", "项", "祝", "阮", "蓝", "席", "季", "童", "贺", "乔", "赖", "龚", "文", "施", "牛", "岳", "齐", "尚", "梅", "辛", "管", "祝", "左", "涂", "谷", "祁", "时", "舒", "耿", "牟", "卜", "路", "詹", "关", "苗", "凌", "费", "纪", "靳", "盛", "童", "欧", "甄", "项", "曲", "成", "游", "阳", "裴", "席", "卫", "查", "屈", "鲍", "位", "覃", "霍", "翁", "隋", "植", "甘", "景", "薄", "单", "包", "司", "柏", "宁", "柯", "阮", "桂", "闵", "欧阳", "太史", "端木", "上官", "司马", "东方", "独孤", "南宫", "万俟", "闻人", "夏侯", "诸葛", "尉迟", "公羊", "赫连", "澹台", "皇甫", "宗政", "濮阳", "公冶", "太叔", "申屠", "公孙", "慕容", "仲孙", "钟离", "长孙", "宇文", "司徒", "鲜于", "司空", "司寇", "西门"]
        
        for surname in surnames {
            // 查找姓氏后面跟着1-2个字的情况
            let pattern = "\(surname)([\u{4e00}-\u{9fff}]{1,2})"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) {
                if let nameRange = Range(match.range, in: text) {
                    return String(text[nameRange])
                }
            }
        }
        
        return "未指定"
    }
    
    /// 清理任务内容
    private func cleanTaskContent(_ content: String, assignee: String) -> String {
        var cleaned = content
        
        // 移除常见的任务标记词
        let markers = ["TODO:", "FIXME:", "任务:", "待办:", "【任务】", "[任务]"]
        for marker in markers {
            cleaned = cleaned.replacingOccurrences(of: marker, with: "")
        }
        
        // 如果内容以负责人开头，移除负责人部分
        if cleaned.hasPrefix(assignee) {
            cleaned = String(cleaned.dropFirst(assignee.count))
            cleaned = cleaned.trimmingCharacters(in: .whitespaces)
        }
        
        // 移除开头的标点符号
        cleaned = cleaned.trimmingCharacters(in: .whitespaces.union(.punctuationCharacters))
        
        // 首字母大写
        if let firstChar = cleaned.first {
            cleaned = String(firstChar).uppercased() + cleaned.dropFirst()
        }
        
        return cleaned
    }
}

// MARK: - 扩展：模拟AI解析
extension TaskExtractionService {
    
    /// 使用模拟AI解析提取任务（更智能的规则）
    func extractTasksWithAI(from transcript: String, recordingId: UUID, completion: @escaping ([Task]) -> Void) {
        isExtracting = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 模拟网络延迟
            Thread.sleep(forTimeInterval: 1.5)
            
            let tasks = self?.simulateAIExtraction(from: transcript, recordingId: recordingId) ?? []
            
            DispatchQueue.main.async {
                self?.extractedTasks = tasks
                self?.isExtracting = false
                completion(tasks)
            }
        }
    }
    
    /// 模拟AI提取逻辑
    private func simulateAIExtraction(from transcript: String, recordingId: UUID) -> [Task] {
        var tasks: [Task] = []
        let lines = transcript.components(separatedBy: .newlines)
        
        // 更复杂的任务识别模式
        let taskPatterns = [
            "(.*?)需要(.*?)完成(.*?)",
            "(.*?)要(.*?)做(.*?)",
            "(.*?)负责(.*?)",
            "安排(.*?)去(.*?)",
            "让(.*?)处理(.*?)",
            "(.*?)得(.*?)准备(.*?)",
            "(.*?)必须(.*?)解决(.*?)",
            "(.*?)应该(.*?)整理(.*?)",
            "(.*?)编写(.*?)",
            "(.*?)设计(.*?)",
            "(.*?)开发(.*?)",
            "(.*?)测试(.*?)",
        ]
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }
            
            // 尝试匹配各种任务模式
            for pattern in taskPatterns {
                if let task = matchTaskPattern(pattern, in: trimmedLine, recordingId: recordingId) {
                    tasks.append(task)
                    break
                }
            }
        }
        
        return tasks.isEmpty ? performExtraction(from: transcript, recordingId: recordingId) : tasks
    }
    
    /// 匹配任务模式
    private func matchTaskPattern(_ pattern: String, in text: String, recordingId: UUID) -> Task? {
        // 简化的模式匹配实现
        // 实际项目中可以使用更复杂的NLP库
        return nil
    }
}
