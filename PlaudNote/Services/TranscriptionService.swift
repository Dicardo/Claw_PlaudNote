//
//  TranscriptionService.swift
//  PlaudNote
//
//  iOS Speech 框架转录服务
//

import Foundation
import Speech
import Combine

class TranscriptionService: ObservableObject {
    @Published var isLoading = false
    @Published var progressMessage = ""
    @Published var errorMessage: String?
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechURLRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        // 设置语言为中文（中国大陆），支持自动检测语言
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        // 允许自动检测语言
        speechRecognizer?.supportsOnDeviceRecognition = true
    }
    
    // MARK: - 权限检查
    
    func checkAuthorization() async -> Bool {
        // 检查语音识别权限
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        
        if speechStatus == .notDetermined {
            await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { _ in
                    continuation.resume()
                }
            }
        }
        
        return SFSpeechRecognizer.authorizationStatus() == .authorized
    }
    
    // MARK: - 转录方法
    
    func transcribe(recording: Recording) {
        guard !isLoading else { return }
        
        Task {
            // 检查权限
            let authorized = await checkAuthorization()
            
            await MainActor.run {
                if !authorized {
                    self.isLoading = false
                    self.errorMessage = "没有语音识别权限，请在设置中开启"
                    return
                }
                
                self.isLoading = true
                self.progressMessage = "准备转录..."
                self.errorMessage = nil
            }
            
            // 检查文件是否存在
            guard FileManager.default.fileExists(atPath: recording.audioFileURL.path) else {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "音频文件不存在"
                }
                return
            }
            
            // 取消之前的任务
            recognitionTask?.cancel()
            recognitionTask = nil
            
            // 创建识别请求
            let request = SFSpeechURLRecognitionRequest(url: recording.audioFileURL)
            request.requiresOnDeviceRecognition = false // 允许使用服务器端识别以获得更好效果
            request.shouldReportPartialResults = false
            
            // 启用自动标点
            if #available(iOS 16.0, *) {
                request.addsPunctuation = true
            }
            
            await MainActor.run {
                self.progressMessage = "正在转录，请稍候..."
            }
            
            // 开始识别
            recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "转录失败: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let result = result else { return }
                
                if result.isFinal {
                    let transcript = result.bestTranscription.formattedString
                    
                    DispatchQueue.main.async {
                        self.isLoading = false
                        
                        // 更新录音的转录文本
                        NotificationCenter.default.post(
                            name: .recordingTranscribed,
                            object: nil,
                            userInfo: [
                                "recordingId": recording.id,
                                "transcript": transcript
                            ]
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - 取消转录
    
    func cancelTranscription() {
        recognitionTask?.cancel()
        recognitionTask = nil
        isLoading = false
        progressMessage = ""
    }
    
    // MARK: - 检查离线支持
    
    @available(iOS 16.0, *)
    func checkOnDeviceSupport() async -> Bool {
        return await SFSpeechRecognizer.hasOnDeviceRecognition()
    }
    
    func checkOnDeviceSupportLegacy() -> Bool {
        // iOS 16 以下版本不支持离线识别
        return false
    }
}

// MARK: - 通知名称扩展
extension Notification.Name {
    static let recordingTranscribed = Notification.Name("recordingTranscribed")
}
