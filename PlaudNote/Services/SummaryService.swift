//
//  SummaryService.swift
//  PlaudNote
//
//  AI 摘要生成服务（使用 Kimi API）
//

import Foundation
import Combine

class SummaryService: ObservableObject {
    @Published var isGeneratingSummary = false
    @Published var isGeneratingTodos = false
    @Published var meetingSummary: String?
    @Published var todos: String?
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 生成会议纪要
    
    func generateMeetingSummary(from transcript: String) {
        guard !isGeneratingSummary else { return }
        
        isGeneratingSummary = true
        errorMessage = nil
        
        let prompt = """
        请根据以下会议转录文本，生成一份简洁的会议纪要。要求：
        1. 列出主要讨论议题
        2. 总结关键决策和结论
        3. 提取重要的数据或信息
        4. 使用 bullet points 格式
        
        转录文本：
        \(transcript)
        """
        
        generateWithKimi(prompt: prompt) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGeneratingSummary = false
                switch result {
                case .success(let text):
                    self?.meetingSummary = text
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - 生成待办事项
    
    func generateTodos(from transcript: String) {
        guard !isGeneratingTodos else { return }
        
        isGeneratingTodos = true
        errorMessage = nil
        
        let prompt = """
        请根据以下会议转录文本，提取所有待办事项（Action Items）。要求：
        1. 每个待办事项包含：任务内容、负责人（如有提及）、截止日期（如有提及）
        2. 使用 checkbox 列表格式
        3. 按优先级排序（如有明确优先级）
        4. 如果未提及负责人，标注为"待分配"
        
        转录文本：
        \(transcript)
        """
        
        generateWithKimi(prompt: prompt) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGeneratingTodos = false
                switch result {
                case .success(let text):
                    self?.todos = text
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - 通用 Kimi API 调用
    
    private func generateWithKimi(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiKey = Config.kimiAPIKey, !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "SummaryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "未配置 Kimi API Key"])))
            return
        }
        
        let url = URL(string: "https://api.moonshot.cn/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "kimi-k2.5",
            "messages": [
                ["role": "system", "content": "你是一个专业的会议助手，擅长从会议记录中提取关键信息。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 2000
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // 打印调试信息
            if let error = error {
                print("[Kimi API Error] \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[Kimi API Status] \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("[Kimi API Error] 无响应数据")
                completion(.failure(NSError(domain: "SummaryService", code: -2, userInfo: [NSLocalizedDescriptionKey: "无响应数据"])))
                return
            }
            
            // 打印原始响应
            if let responseString = String(data: data, encoding: .utf8) {
                print("[Kimi API Response] \(responseString.prefix(500))")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    print("[Kimi API Success] 生成成功")
                    completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let error = json["error"] as? [String: Any],
                          let message = error["message"] as? String {
                    print("[Kimi API Error] \(message)")
                    completion(.failure(NSError(domain: "SummaryService", code: -3, userInfo: [NSLocalizedDescriptionKey: message])))
                } else {
                    print("[Kimi API Error] 解析响应失败")
                    completion(.failure(NSError(domain: "SummaryService", code: -4, userInfo: [NSLocalizedDescriptionKey: "解析响应失败"])))
                }
            } catch {
                print("[Kimi API Error] JSON解析失败: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}
