//
//  RecordingDetailView.swift
//  PlaudNote
//
//  录音详情界面 - 播放、转录、摘要
//

import SwiftUI

struct RecordingDetailView: View {
    let recording: Recording
    @EnvironmentObject var store: RecordingStore
    @StateObject private var player = AudioPlayer()
    @StateObject private var transcriptionService = TranscriptionService()
    @StateObject private var summaryService = SummaryService()
    @State private var selectedTab = 0
    @State private var showRenameAlert = false
    @State private var newTitle = ""
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 播放器卡片
                PlayerCardView(
                    recording: recording,
                    player: player,
                    isPlaying: player.isPlaying,
                    currentTime: player.currentTime,
                    duration: recording.duration
                )
                
                // 标签页切换
                Picker("", selection: $selectedTab) {
                    Text("转录文字").tag(0)
                    Text("会议纪要").tag(1)
                    Text("待办事项").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // 内容区域
                Group {
                    switch selectedTab {
                    case 0:
                        TranscriptView(
                            recording: recording,
                            transcriptionService: transcriptionService
                        )
                    case 1:
                        MeetingSummaryView(
                            recording: recording,
                            summaryService: summaryService
                        )
                    case 2:
                        TodoView(
                            recording: recording,
                            summaryService: summaryService
                        )
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(recording.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        newTitle = recording.title
                        showRenameAlert = true
                    } label: {
                        Label("重命名", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("重命名录音", isPresented: $showRenameAlert) {
            TextField("新标题", text: $newTitle)
            Button("取消", role: .cancel) { }
            Button("保存") {
                if !newTitle.isEmpty {
                    store.renameRecording(recording, to: newTitle)
                }
            }
        } message: {
            Text("输入新的录音标题")
        }
        .confirmationDialog("确认删除", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("删除录音", role: .destructive) {
                store.deleteRecording(recording)
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("此操作无法撤销")
        }
        .onAppear {
            player.prepare(url: recording.audioFileURL)
        }
        .onDisappear {
            player.stop()
        }
    }
}

// MARK: - 播放器卡片
struct PlayerCardView: View {
    let recording: Recording
    @ObservedObject var player: AudioPlayer
    let isPlaying: Bool
    let currentTime: TimeInterval
    let duration: TimeInterval
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1.0, currentTime / duration)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal)
            
            // 时间显示
            HStack {
                Text(formatTime(currentTime))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatTime(duration))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 控制按钮
            HStack(spacing: 40) {
                Button {
                    player.seek(to: max(0, currentTime - 15))
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Button {
                    if isPlaying {
                        player.pause()
                    } else {
                        player.play()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
                
                Button {
                    player.seek(to: min(duration, currentTime + 15))
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.vertical, 20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 转录文字视图
struct TranscriptView: View {
    let recording: Recording
    @ObservedObject var transcriptionService: TranscriptionService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if recording.isTranscribed, !recording.transcript.isEmpty {
                // 已转录
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("转录完成")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = recording.transcript
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.accentColor)
                    }
                }
                
                Text(recording.transcript)
                    .font(.body)
                    .lineSpacing(6)
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(12)
            } else if transcriptionService.isLoading {
                // 转录中
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("正在转录音频...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if !transcriptionService.progressMessage.isEmpty {
                        Text(transcriptionService.progressMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                // 未转录
                VStack(spacing: 16) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("尚未转录")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button {
                        transcriptionService.transcribe(recording: recording)
                    } label: {
                        Label("开始转录", systemImage: "waveform")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - 会议纪要视图
struct MeetingSummaryView: View {
    let recording: Recording
    @ObservedObject var summaryService: SummaryService
    @State private var hasGenerated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !recording.transcript.isEmpty {
                if summaryService.isGeneratingSummary {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("正在生成会议纪要...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if hasGenerated, let summary = summaryService.meetingSummary {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text("会议纪要")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = summary
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    Text(summary)
                        .font(.body)
                        .lineSpacing(6)
                        .padding()
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(12)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text("生成会议纪要")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            summaryService.generateMeetingSummary(from: recording.transcript)
                            hasGenerated = true
                        } label: {
                            Label("开始生成", systemImage: "sparkles")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("请先完成音频转录")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - 待办事项视图
struct TodoView: View {
    let recording: Recording
    @ObservedObject var summaryService: SummaryService
    @State private var hasGenerated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !recording.transcript.isEmpty {
                if summaryService.isGeneratingTodos {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("正在提取待办事项...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if hasGenerated, let todos = summaryService.todos {
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(.purple)
                        Text("待办事项")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = todos
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    Text(todos)
                        .font(.body)
                        .lineSpacing(6)
                        .padding()
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(12)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checklist")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text("提取待办事项")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            summaryService.generateTodos(from: recording.transcript)
                            hasGenerated = true
                        } label: {
                            Label("开始提取", systemImage: "sparkles")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("请先完成音频转录")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

#Preview {
    NavigationView {
        RecordingDetailView(recording: Recording.mock())
            .environmentObject(RecordingStore())
    }
}
