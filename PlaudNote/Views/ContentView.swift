//
//  ContentView.swift
//  PlaudNote
//
//  主界面 - 包含录音列表和录音按钮
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: RecordingStore
    @EnvironmentObject var taskStore: TaskStore
    @State private var showRecordingSheet = false
    @State private var searchText = ""
    @State private var selectedTab = 0
    
    var filteredRecordings: [Recording] {
        if searchText.isEmpty {
            return store.recordings.sorted { $0.createdAt > $1.createdAt }
        } else {
            return store.recordings.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.transcript.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 搜索栏
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    if store.recordings.isEmpty {
                        EmptyStateView()
                    } else {
                        RecordingListView(recordings: filteredRecordings)
                    }
                }
            }
            .navigationTitle("录音笔记")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: TaskBoardView()) {
                        HStack(spacing: 4) {
                            Image(systemName: "checklist")
                            if taskStore.tasks.count > 0 {
                                Text("\(taskStore.tasks.count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                        .foregroundColor(.accentColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showRecordingSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showRecordingSheet) {
                RecordingView()
                    .environmentObject(store)
            }
        }
    }
}

// MARK: - 搜索栏
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索录音...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "waveform")
                .font(.system(size: 80))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("还没有录音")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("点击右上角 + 按钮开始录音")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - 录音列表视图
struct RecordingListView: View {
    let recordings: [Recording]
    @EnvironmentObject var store: RecordingStore
    
    var body: some View {
        List {
            ForEach(recordings) { recording in
                NavigationLink(destination: RecordingDetailView(recording: recording)) {
                    RecordingRowView(recording: recording)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        store.deleteRecording(recording)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - 录音行视图
struct RecordingRowView: View {
    let recording: Recording
    
    var body: some View {
        HStack(spacing: 16) {
            // 录音图标
            ZStack {
                Circle()
                    .fill(recording.isTranscribed ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: recording.isTranscribed ? "checkmark.circle" : "mic")
                    .font(.system(size: 20))
                    .foregroundColor(recording.isTranscribed ? .green : .orange)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recording.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Text(recording.formattedDuration)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text(recording.formattedDate)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if recording.isTranscribed {
                Image(systemName: "text.badge.checkmark")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
        .environmentObject(RecordingStore())
        .environmentObject(TaskStore())
}
