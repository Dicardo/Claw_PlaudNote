//
//  AudioRecorder.swift
//  PlaudNote
//
//  音频录制管理
//

import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var currentTime: TimeInterval = 0
    @Published var powerLevels: [Float] = Array(repeating: 0, count: 10)
    
    var audioFileURL: URL?
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var powerTimer: Timer?
    
    var formattedTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - 录音控制
    
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            let fileName = "\(UUID().uuidString).m4a"
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = documentsPath.appendingPathComponent(fileName)
            
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            audioFileURL = audioURL
            isRecording = true
            currentTime = 0
            
            // 启动计时器
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.currentTime += 1
            }
            
            // 启动音量监测
            powerTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updatePowerLevels()
            }
            
        } catch {
            print("录音启动失败: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        timer?.invalidate()
        timer = nil
        
        powerTimer?.invalidate()
        powerTimer = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func cancelRecording() {
        audioRecorder?.stop()
        audioRecorder?.deleteRecording()
        
        isRecording = false
        currentTime = 0
        
        timer?.invalidate()
        timer = nil
        
        powerTimer?.invalidate()
        powerTimer = nil
        
        // 删除文件
        if let url = audioFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    // MARK: - 音量监测
    
    private func updatePowerLevels() {
        guard let recorder = audioRecorder else { return }
        
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        
        // 更新音量数组
        var newLevels = powerLevels
        newLevels.removeFirst()
        newLevels.append(power)
        powerLevels = newLevels
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("录音失败")
        }
    }
}
