//
//  Config.swift
//  PlaudNote
//
//  应用配置 - API Key 等
//

import Foundation

enum Config {
    // MARK: - Kimi API Key
    
    static var kimiAPIKey: String? {
        // 硬编码 API Key（已配置）
        return "sk-Gh2rIWY9Qr4qdOX8bl0C9AA4zoJI5N8wquDQj2mku0A7iajG"
    }
    
    // MARK: - 其他配置
    
    static let appName = "PlaudNote"
    static let appVersion = "1.0.0"
    
    // Kimi API 配置（用于 AI 摘要）
    static let kimiModel = "kimi-k2.5"
    static let kimiMaxTokens = 2000
    static let kimiTemperature = 0.3
}
