//
//  RecordingStore.swift
//  PlaudNote
//
//  录音数据管理 - 使用 UserDefaults 持久化
//

import Foundation
import Combine

class RecordingStore: ObservableObject {
    @Published var recordings: [Recording] = []
    
    private let saveKey = "plaud_recordings"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadRecordings()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTranscriptionCompleted(_:)),
            name: .recordingTranscribed,
            object: nil
        )
    }
    
    @objc private func handleTranscriptionCompleted(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let recordingId = userInfo["recordingId"] as? UUID,
              let transcript = userInfo["transcript"] as? String else {
            return
        }
        
        updateTranscript(forId: recordingId, transcript: transcript)
    }
    
    func updateTranscript(forId id: UUID, transcript: String) {
        if let index = recordings.firstIndex(where: { $0.id == id }) {
            recordings[index].transcript = transcript
            recordings[index].isTranscribed = true
            saveRecordings()
        }
    }
    
    // MARK: - 数据操作
    
    func addRecording(_ recording: Recording) {
        recordings.append(recording)
        saveRecordings()
    }
    
    func deleteRecording(_ recording: Recording) {
        // 删除音频文件
        try? FileManager.default.removeItem(at: recording.audioFileURL)
        
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }
    
    func renameRecording(_ recording: Recording, to newTitle: String) {
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index].title = newTitle
            saveRecordings()
        }
    }
    
    func updateTranscript(for recording: Recording, transcript: String) {
        updateTranscript(forId: recording.id, transcript: transcript)
    }
    
    // MARK: - 持久化
    
    private func saveRecordings() {
        // 只保存元数据，不保存 URL 对象
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let encoded = try? encoder.encode(recordings) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadRecordings() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // 自定义解码处理 URL
        if let recordings = try? decoder.decode([Recording].self, from: data) {
            // 验证文件是否存在
            self.recordings = recordings.filter { recording in
                FileManager.default.fileExists(atPath: recording.audioFileURL.path)
            }
        }
    }
}
