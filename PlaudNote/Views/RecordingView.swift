//
//  RecordingView.swift
//  PlaudNote
//
//  录音界面 - 开始/停止录音，显示录音波形
//

import SwiftUI

struct RecordingView: View {
    @EnvironmentObject var store: RecordingStore
    @Environment(\.dismiss) var dismiss
    @StateObject private var recorder = AudioRecorder()
    @State private var showSaveDialog = false
    @State private var recordingTitle = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // 录音时长
                    Text(recorder.formattedTime)
                        .font(.system(size: 64, weight: .thin, design: .monospaced))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                    
                    // 录音状态
                    Text(recorder.isRecording ? "正在录音..." : "准备录音")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 波形动画
                    AudioWaveformView(isRecording: recorder.isRecording, powerLevels: recorder.powerLevels)
                        .frame(height: 100)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // 控制按钮
                    HStack(spacing: 60) {
                        // 取消按钮
                        Button(action: {
                            recorder.cancelRecording()
                            dismiss()
                        }) {
                            VStack {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 50))
                                Text("取消")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        .disabled(recorder.isRecording)
                        .opacity(recorder.isRecording ? 0.5 : 1)
                        
                        // 录音/停止按钮
                        Button(action: {
                            if recorder.isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(recorder.isRecording ? Color.red : Color.accentColor)
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // 占位
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                            Text("完成")
                                .font(.caption)
                        }
                        .foregroundColor(.clear)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("新录音")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        if recorder.isRecording {
                            recorder.cancelRecording()
                        }
                        dismiss()
                    }
                }
            }
            .alert("保存录音", isPresented: $showSaveDialog) {
                TextField("录音标题", text: $recordingTitle)
                Button("取消", role: .cancel) {
                    recorder.cancelRecording()
                    dismiss()
                }
                Button("保存") {
                    saveRecording()
                }
            } message: {
                Text("为这个录音添加一个标题")
            }
        }
    }
    
    private func startRecording() {
        recorder.startRecording()
    }
    
    private func stopRecording() {
        recorder.stopRecording()
        recordingTitle = "录音 \(Date().formatted(date: .numeric, time: .shortened))"
        showSaveDialog = true
    }
    
    private func saveRecording() {
        if let url = recorder.audioFileURL {
            let recording = Recording(
                title: recordingTitle.isEmpty ? "未命名录音" : recordingTitle,
                audioFileURL: url,
                duration: recorder.currentTime
            )
            store.addRecording(recording)
        }
        dismiss()
    }
}

// MARK: - 音频波形视图
struct AudioWaveformView: View {
    let isRecording: Bool
    let powerLevels: [Float]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<30, id: \.self) { index in
                    BarView(
                        height: barHeight(for: index, in: geometry.size.height),
                        isRecording: isRecording
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.1), value: powerLevels)
        }
    }
    
    private func barHeight(for index: Int, in maxHeight: CGFloat) -> CGFloat {
        guard isRecording, !powerLevels.isEmpty else {
            return maxHeight * 0.1
        }
        
        let levelIndex = index % powerLevels.count
        let level = powerLevels[levelIndex]
        let normalizedLevel = CGFloat((level + 60) / 60) // 将 -60~0 dB 映射到 0~1
        let clampedLevel = max(0.1, min(1.0, normalizedLevel))
        
        return maxHeight * clampedLevel
    }
}

// MARK: - 波形条
struct BarView: View {
    let height: CGFloat
    let isRecording: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isRecording ? Color.accentColor : Color.secondary.opacity(0.3))
            .frame(width: 6, height: height)
            .animation(.easeInOut(duration: 0.1), value: height)
    }
}

#Preview {
    RecordingView()
        .environmentObject(RecordingStore())
}
