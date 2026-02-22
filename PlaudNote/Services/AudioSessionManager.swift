//
//  AudioSessionManager.swift
//  PlaudNote
//
//  音频会话管理
//

import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()
    
    private init() {}
    
    func configure() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("音频会话配置失败: \(error.localizedDescription)")
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
}
