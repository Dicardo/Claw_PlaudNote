//
//  PlaudNoteApp.swift
//  PlaudNote
//
//  AI 录音笔应用 - 主入口
//

import SwiftUI

@main
struct PlaudNoteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(RecordingStore())
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 配置音频会话
        AudioSessionManager.shared.configure()
        return true
    }
}
