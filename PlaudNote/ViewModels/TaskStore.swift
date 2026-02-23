//
//  TaskStore.swift
//  PlaudNote
//
//  任务数据管理 - 增删改查、状态更新
//

import Foundation
import Combine

class TaskStore: ObservableObject {
    
    @Published var tasks: [Task] = []
    @Published var meetingSummaries: [MeetingSummary] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let tasksKey = "plaudnote_tasks"
    private let summariesKey = "plaudnote_meeting_summaries"
    
    // MARK: - 初始化
    
    init() {
        loadFromDisk()
    }
    
    // MARK: - 任务管理
    
    /// 添加任务
    func addTask(_ task: Task) {
        tasks.append(task)
        saveToDisk()
    }
    
    /// 添加多个任务
    func addTasks(_ newTasks: [Task]) {
        tasks.append(contentsOf: newTasks)
        saveToDisk()
    }
    
    /// 删除任务
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveToDisk()
    }
    
    /// 删除指定录音的所有任务
    func deleteTasks(for recordingId: UUID) {
        tasks.removeAll { $0.sourceRecordingId == recordingId }
        saveToDisk()
    }
    
    /// 更新任务
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveToDisk()
        }
    }
    
    /// 更新任务状态
    func updateTaskStatus(id: UUID, status: TaskStatus) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].updateStatus(status)
            saveToDisk()
        }
    }
    
    /// 更新任务内容
    func updateTaskContent(id: UUID, content: String) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].updateContent(content)
            saveToDisk()
        }
    }
    
    /// 更新任务负责人
    func updateTaskAssignee(id: UUID, assignee: String) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].updateAssignee(assignee)
            saveToDisk()
        }
    }
    
    /// 获取任务（按ID）
    func getTask(by id: UUID) -> Task? {
        return tasks.first { $0.id == id }
    }
    
    /// 获取指定录音的所有任务
    func getTasks(for recordingId: UUID) -> [Task] {
        return tasks.filter { $0.sourceRecordingId == recordingId }
    }
    
    /// 获取所有任务（按负责人分组）
    func getTasksGroupedByAssignee() -> [String: [Task]] {
        return Dictionary(grouping: tasks) { $0.assignee }
    }
    
    /// 获取指定负责人的所有任务
    func getTasks(forAssignee assignee: String) -> [Task] {
        return tasks.filter { $0.assignee == assignee }
    }
    
    /// 获取所有负责人列表
    func getAllAssignees() -> [String] {
        return Array(Set(tasks.map { $0.assignee })).sorted()
    }
    
    /// 获取指定状态的任务
    func getTasks(withStatus status: TaskStatus) -> [Task] {
        return tasks.filter { $0.status == status }
    }
    
    /// 搜索任务
    func searchTasks(query: String) -> [Task] {
        let lowerQuery = query.lowercased()
        return tasks.filter {
            $0.content.lowercased().contains(lowerQuery) ||
            $0.assignee.lowercased().contains(lowerQuery)
        }
    }
    
    /// 切换任务状态（循环切换：待办 -> 进行中 -> 已完成）
    func toggleTaskStatus(id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            let currentStatus = tasks[index].status
            let nextStatus: TaskStatus
            
            switch currentStatus {
            case .todo:
                nextStatus = .inProgress
            case .inProgress:
                nextStatus = .completed
            case .completed:
                nextStatus = .todo
            }
            
            tasks[index].updateStatus(nextStatus)
            saveToDisk()
        }
    }
    
    /// 获取任务统计
    func getTaskStatistics() -> (total: Int, todo: Int, inProgress: Int, completed: Int) {
        let total = tasks.count
        let todo = tasks.filter { $0.status == .todo }.count
        let inProgress = tasks.filter { $0.status == .inProgress }.count
        let completed = tasks.filter { $0.status == .completed }.count
        
        return (total, todo, inProgress, completed)
    }
    
    // MARK: - 会议纪要管理
    
    /// 添加会议纪要
    func addMeetingSummary(_ summary: MeetingSummary) {
        // 如果已存在该录音的纪要，先删除
        meetingSummaries.removeAll { $0.recordingId == summary.recordingId }
        meetingSummaries.append(summary)
        saveToDisk()
    }
    
    /// 删除会议纪要
    func deleteMeetingSummary(_ summary: MeetingSummary) {
        meetingSummaries.removeAll { $0.id == summary.id }
        saveToDisk()
    }
    
    /// 删除指定录音的会议纪要
    func deleteMeetingSummary(for recordingId: UUID) {
        meetingSummaries.removeAll { $0.recordingId == recordingId }
        saveToDisk()
    }
    
    /// 获取会议纪要（按录音ID）
    func getMeetingSummary(for recordingId: UUID) -> MeetingSummary? {
        return meetingSummaries.first { $0.recordingId == recordingId }
    }
    
    /// 更新会议纪要
    func updateMeetingSummary(_ summary: MeetingSummary) {
        if let index = meetingSummaries.firstIndex(where: { $0.id == summary.id }) {
            meetingSummaries[index] = summary
            saveToDisk()
        }
    }
    
    /// 关联任务到会议纪要
    func linkTaskToSummary(taskId: UUID, summaryId: UUID) {
        if let index = meetingSummaries.firstIndex(where: { $0.id == summaryId }) {
            meetingSummaries[index].addActionItem(taskId)
            saveToDisk()
        }
    }
    
    /// 从会议纪要中移除任务关联
    func unlinkTaskFromSummary(taskId: UUID, summaryId: UUID) {
        if let index = meetingSummaries.firstIndex(where: { $0.id == summaryId }) {
            meetingSummaries[index].removeActionItem(taskId)
            saveToDisk()
        }
    }
    
    // MARK: - 数据持久化
    
    /// 保存到磁盘
    private func saveToDisk() {
        do {
            let tasksData = try JSONEncoder().encode(tasks)
            let summariesData = try JSONEncoder().encode(meetingSummaries)
            
            UserDefaults.standard.set(tasksData, forKey: tasksKey)
            UserDefaults.standard.set(summariesData, forKey: summariesKey)
        } catch {
            print("保存任务数据失败: \(error)")
        }
    }
    
    /// 从磁盘加载
    private func loadFromDisk() {
        if let tasksData = UserDefaults.standard.data(forKey: tasksKey) {
            do {
                tasks = try JSONDecoder().decode([Task].self, from: tasksData)
            } catch {
                print("加载任务数据失败: \(error)")
                tasks = []
            }
        }
        
        if let summariesData = UserDefaults.standard.data(forKey: summariesKey) {
            do {
                meetingSummaries = try JSONDecoder().decode([MeetingSummary].self, from: summariesData)
            } catch {
                print("加载会议纪要数据失败: \(error)")
                meetingSummaries = []
            }
        }
    }
    
    /// 清除所有数据
    func clearAllData() {
        tasks.removeAll()
        meetingSummaries.removeAll()
        UserDefaults.standard.removeObject(forKey: tasksKey)
        UserDefaults.standard.removeObject(forKey: summariesKey)
    }
}

// MARK: - 扩展：批量操作
extension TaskStore {
    
    /// 批量更新任务状态
    func batchUpdateStatus(taskIds: [UUID], status: TaskStatus) {
        for id in taskIds {
            if let index = tasks.firstIndex(where: { $0.id == id }) {
                tasks[index].updateStatus(status)
            }
        }
        saveToDisk()
    }
    
    /// 批量删除任务
    func batchDeleteTasks(taskIds: [UUID]) {
        tasks.removeAll { taskIds.contains($0.id) }
        saveToDisk()
    }
    
    /// 批量更新负责人
    func batchUpdateAssignee(taskIds: [UUID], assignee: String) {
        for id in taskIds {
            if let index = tasks.firstIndex(where: { $0.id == id }) {
                tasks[index].updateAssignee(assignee)
            }
        }
        saveToDisk()
    }
}
