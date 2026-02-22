//
//  Config.swift
//  PlaudNote
//
//  应用配置 - API Key 等
//

import Foundation

enum Config {
    // MARK: - Kimi API Key
    // 
    // 方式1: 从 Info.plist 读取（推荐）
    // 在项目的 Info.plist 中添加键：KIMI_API_KEY
    //
    // 方式2: 从环境变量读取（开发时使用）
    // 在 Xcode 的 Scheme 中设置环境变量
    
    static var kimiAPIKey: String? {
        // 优先从 Info.plist 读取
        if let key = Bundle.main.infoDictionary?["KIMI_API_KEY"] as? String, !key.isEmpty {
            return key
        }
        
        // 从环境变量读取（用于开发调试）
        if let key = ProcessInfo.processInfo.environment["KIMI_API_KEY"], !key.isEmpty {
            return key
        }
        
        // 如果都没有，返回 nil
        return nil
    }
    
    // MARK: - 其他配置
    
    static let appName = "PlaudNote"
    static let appVersion = "1.0.0"
    
    // Whisper API 配置（OpenAI，用于语音转文字）
    static let whisperModel = "whisper-1"
    static let whisperLanguage: String? = nil // nil 表示自动检测，或设置为 "zh" 指定中文
    
    // Kimi API 配置（用于 AI 摘要）
    static let kimiModel = "kimi-coding/k2p5"
    static let kimiMaxTokens = 2000
    static let kimiTemperature = 0.3
}
