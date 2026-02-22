//
//  AudioPlayer.swift
//  PlaudNote
//
//  音频播放管理
//

import Foundation
import AVFoundation
import Combine

class AudioPlayer: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    // MARK: - 播放控制
    
    func prepare(url: URL) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            
            duration = player?.duration ?? 0
            currentTime = 0
            
        } catch {
            print("音频准备失败: \(error.localizedDescription)")
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
        
        // 启动进度更新
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            self.currentTime = player.currentTime
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
    
    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        currentTime = 0
        timer?.invalidate()
        timer = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        timer?.invalidate()
        timer = nil
    }
}
