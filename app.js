/**
 * PlaudNote - AI 录音笔 Web 应用
 * 主要 JavaScript 逻辑
 */

// ==================== 全局状态 ====================
const AppState = {
    isRecording: false,
    isPaused: false,
    mediaRecorder: null,
    audioChunks: [],
    recordingStartTime: null,
    recordingDuration: 0,
    timerInterval: null,
    audioContext: null,
    analyser: null,
    dataArray: null,
    animationId: null,
    recordings: [],
    transcriptions: [],
    tasks: [],
    currentView: 'recorder'
};

// ==================== 存储管理 ====================
const Storage = {
    KEYS: {
        RECORDINGS: 'plaud_recordings',
        TRANSCRIPTIONS: 'plaud_transcriptions',
        TASKS: 'plaud_tasks'
    },

    save(key, data) {
        try {
            localStorage.setItem(key, JSON.stringify(data));
        } catch (e) {
            console.error('Storage save error:', e);
        }
    },

    load(key, defaultValue = []) {
        try {
            const data = localStorage.getItem(key);
            return data ? JSON.parse(data) : defaultValue;
        } catch (e) {
            console.error('Storage load error:', e);
            return defaultValue;
        }
    },

    clear() {
        Object.values(this.KEYS).forEach(key => {
            localStorage.removeItem(key);
        });
    }
};

// ==================== DOM 元素 ====================
const DOM = {
    // 导航
    navItems: document.querySelectorAll('.nav-item'),
    views: document.querySelectorAll('.view'),
    
    // 录音控制
    recordBtn: document.getElementById('recordBtn'),
    pauseBtn: document.getElementById('pauseBtn'),
    stopBtn: document.getElementById('stopBtn'),
    recordingIndicator: document.getElementById('recordingIndicator'),
    recordingTimer: document.getElementById('recordingTimer'),
    visualizer: document.getElementById('visualizer'),
    audioUpload: document.getElementById('audioUpload'),
    
    // 列表容器
    recordingsList: document.getElementById('recordingsList'),
    transcriptionsList: document.getElementById('transcriptionsList'),
    totalTasksList: document.getElementById('totalTasksList'),
    personalTasksList: document.getElementById('personalTasksList'),
    totalTaskCount: document.getElementById('totalTaskCount'),
    personalTaskCount: document.getElementById('personalTaskCount'),
    
    // 模态框
    playerModal: document.getElementById('playerModal'),
    transcriptionModal: document.getElementById('transcriptionModal'),
    summaryModal: document.getElementById('summaryModal'),
    confirmModal: document.getElementById('confirmModal'),
    closePlayerModal: document.getElementById('closePlayerModal'),
    closeTranscriptionModal: document.getElementById('closeTranscriptionModal'),
    closeSummaryModal: document.getElementById('closeSummaryModal'),
    audioPlayer: document.getElementById('audioPlayer'),
    playerTitle: document.getElementById('playerTitle'),
    playerInfo: document.getElementById('playerInfo'),
    
    // 转录详情
    transcriptionTitle: document.getElementById('transcriptionTitle'),
    transcriptText: document.getElementById('transcriptText'),
    summaryText: document.getElementById('summaryText'),
    extractedTasks: document.getElementById('extractedTasks'),
    tabBtns: document.querySelectorAll('.tab-btn'),
    tabContents: document.querySelectorAll('.tab-content'),
    
    // 确认对话框
    confirmTitle: document.getElementById('confirmTitle'),
    confirmMessage: document.getElementById('confirmMessage'),
    cancelConfirm: document.getElementById('cancelConfirm'),
    confirmAction: document.getElementById('confirmAction'),
    
    // 其他
    clearDataBtn: document.getElementById('clearDataBtn'),
    toast: document.getElementById('toast'),
    toastMessage: document.getElementById('toastMessage')
};

// ==================== 工具函数 ====================
const Utils = {
    generateId() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2);
    },

    formatDuration(seconds) {
        const hrs = Math.floor(seconds / 3600);
        const mins = Math.floor((seconds % 3600) / 60);
        const secs = seconds % 60;
        return `${hrs.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    },

    formatDate(dateStr) {
        const date = new Date(dateStr);
        return date.toLocaleString('zh-CN', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        });
    },

    formatFileSize(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    },

    showToast(message, type = 'success') {
        DOM.toastMessage.textContent = message;
        DOM.toast.querySelector('i').className = type === 'success' 
            ? 'fas fa-check-circle' 
            : 'fas fa-exclamation-circle';
        DOM.toast.classList.add('show');
        setTimeout(() => DOM.toast.classList.remove('show'), 3000);
    }
};

// ==================== 录音功能 ====================
const Recorder = {
    async init() {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            AppState.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            AppState.analyser = AppState.audioContext.createAnalyser();
            const source = AppState.audioContext.createMediaStreamSource(stream);
            source.connect(AppState.analyser);
            AppState.analyser.fftSize = 256;
            const bufferLength = AppState.analyser.frequencyBinCount;
            AppState.dataArray = new Uint8Array(bufferLength);
            
            AppState.mediaRecorder = new MediaRecorder(stream);
            AppState.mediaRecorder.ondataavailable = (e) => {
                AppState.audioChunks.push(e.data);
            };
            AppState.mediaRecorder.onstop = this.onRecordingStop.bind(this);
            
            this.setupVisualizer();
            return true;
        } catch (err) {
            console.error('录音初始化失败:', err);
            Utils.showToast('无法访问麦克风，请检查权限设置', 'error');
            return false;
        }
    },

    setupVisualizer() {
        const canvas = DOM.visualizer;
        const ctx = canvas.getContext('2d');
        canvas.width = canvas.offsetWidth;
        canvas.height = canvas.offsetHeight;

        const draw = () => {
            if (!AppState.isRecording || AppState.isPaused) {
                ctx.clearRect(0, 0, canvas.width, canvas.height);
                if (AppState.isRecording) {
                    AppState.animationId = requestAnimationFrame(draw);
                }
                return;
            }

            AppState.animationId = requestAnimationFrame(draw);
            AppState.analyser.getByteFrequencyData(AppState.dataArray);

            ctx.clearRect(0, 0, canvas.width, canvas.height);
            
            const barWidth = (canvas.width / AppState.dataArray.length) * 2.5;
            let barHeight;
            let x = 0;

            for (let i = 0; i < AppState.dataArray.length; i++) {
                barHeight = (AppState.dataArray[i] / 255) * canvas.height * 0.8;
                
                const gradient = ctx.createLinearGradient(0, canvas.height - barHeight, 0, canvas.height);
                gradient.addColorStop(0, '#6366f1');
                gradient.addColorStop(1, '#818cf8');
                
                ctx.fillStyle = gradient;
                ctx.fillRect(x, canvas.height - barHeight, barWidth, barHeight);
                
                x += barWidth + 1;
            }
        };

        AppState.animationId = requestAnimationFrame(draw);
    },

    async start() {
        if (!AppState.mediaRecorder) {
            const initialized = await this.init();
            if (!initialized) return;
        }

        AppState.audioChunks = [];
        AppState.mediaRecorder.start();
        AppState.isRecording = true;
        AppState.isPaused = false;
        AppState.recordingStartTime = Date.now();
        AppState.recordingDuration = 0;
        
        this.startTimer();
        this.updateUIState();
        this.setupVisualizer();
        
        DOM.recordingIndicator.classList.add('recording');
        Utils.showToast('开始录音');
    },

    pause() {
        if (AppState.isPaused) {
            AppState.mediaRecorder.resume();
            AppState.isPaused = false;
            AppState.recordingStartTime = Date.now() - AppState.recordingDuration * 1000;
            this.startTimer();
            Utils.showToast('继续录音');
        } else {
            AppState.mediaRecorder.pause();
            AppState.isPaused = true;
            this.stopTimer();
            Utils.showToast('录音已暂停');
        }
        this.updateUIState();
    },

    stop() {
        AppState.mediaRecorder.stop();
        AppState.isRecording = false;
        AppState.isPaused = false;
        this.stopTimer();
        this.updateUIState();
        
        DOM.recordingIndicator.classList.remove('recording');
        
        // 停止所有音轨
        AppState.mediaRecorder.stream.getTracks().forEach(track => track.stop());
        
        if (AppState.audioContext) {
            AppState.audioContext.close();
            AppState.audioContext = null;
        }
        
        if (AppState.animationId) {
            cancelAnimationFrame(AppState.animationId);
        }
    },

    onRecordingStop() {
        const audioBlob = new Blob(AppState.audioChunks, { type: 'audio/webm' });
        const recording = {
            id: Utils.generateId(),
            title: `录音 ${new Date().toLocaleString('zh-CN')}`,
            blob: audioBlob,
            url: URL.createObjectURL(audioBlob),
            duration: AppState.recordingDuration,
            size: audioBlob.size,
            createdAt: new Date().toISOString()
        };
        
        // 保存录音元数据（不包含 blob）
        const recordingMeta = {
            id: recording.id,
            title: recording.title,
            duration: recording.duration,
            size: recording.size,
            createdAt: recording.createdAt
        };
        
        AppState.recordings.unshift(recordingMeta);
        Storage.save(Storage.KEYS.RECORDINGS, AppState.recordings);
        
        // 将 blob 存储到 IndexedDB 或内存中
        this.saveAudioBlob(recording.id, audioBlob);
        
        Utils.showToast('录音已保存');
        
        // 自动开始转录
        this.transcribeRecording(recording.id, audioBlob);
        
        // 重置状态
        AppState.mediaRecorder = null;
        AppState.audioChunks = [];
        AppState.recordingDuration = 0;
        DOM.recordingTimer.textContent = '00:00:00';
        
        // 刷新录音列表
        UI.renderRecordings();
    },

    saveAudioBlob(id, blob) {
        // 使用内存存储，实际应用中可以使用 IndexedDB
        if (!window.audioBlobs) window.audioBlobs = {};
        window.audioBlobs[id] = blob;
    },

    getAudioBlob(id) {
        return window.audioBlobs ? window.audioBlobs[id] : null;
    },

    startTimer() {
        AppState.timerInterval = setInterval(() => {
            AppState.recordingDuration = Math.floor((Date.now() - AppState.recordingStartTime) / 1000);
            DOM.recordingTimer.textContent = Utils.formatDuration(AppState.recordingDuration);
        }, 1000);
    },

    stopTimer() {
        clearInterval(AppState.timerInterval);
    },

    updateUIState() {
        DOM.recordBtn.disabled = AppState.isRecording;
        DOM.pauseBtn.disabled = !AppState.isRecording;
        DOM.stopBtn.disabled = !AppState.isRecording;
        
        DOM.recordBtn.innerHTML = AppState.isRecording 
            ? '<i class="fas fa-circle"></i><span>录音中...</span>'
            : '<i class="fas fa-circle"></i><span>开始录音</span>';
        
        DOM.pauseBtn.innerHTML = AppState.isPaused
            ? '<i class="fas fa-play"></i><span>继续</span>'
            : '<i class="fas fa-pause"></i><span>暂停</span>';
    },

    async transcribeRecording(recordingId, audioBlob) {
        // 创建转录记录
        const transcription = {
            id: Utils.generateId(),
            recordingId: recordingId,
            status: 'processing',
            text: '',
            summary: '',
            tasks: [],
            createdAt: new Date().toISOString()
        };
        
        AppState.transcriptions.unshift(transcription);
        Storage.save(Storage.KEYS.TRANSCRIPTIONS, AppState.transcriptions);
        
        // 模拟 AI 转录过程
        setTimeout(() => {
            this.processTranscription(transcription.id);
        }, 2000);
    },

    async processTranscription(transcriptionId) {
        const transcription = AppState.transcriptions.find(t => t.id === transcriptionId);
        if (!transcription) return;

        // 模拟 AI 转录结果
        const mockTranscriptions = [
            `今天的会议主要讨论了 Q4 的产品规划。\n\n首先，产品经理介绍了新功能的优先级。我们需要在月底前完成用户反馈系统的开发。\n\n技术负责人提到，目前后端架构需要优化，建议引入新的缓存策略来提升性能。\n\n关于市场推广，营销团队计划在下周启动新的广告投放活动，预算为 50 万元。\n\n最后，大家一致同意每周五下午进行进度同步会议。`,
            `项目周会记录：\n\n1. 前端开发进度：已完成 80%，预计下周可以进入测试阶段\n2. 后端 API 开发：遇到一些问题，需要额外的 3 天时间解决\n3. UI 设计：新版本的界面设计已经定稿，可以开始切图\n4. 测试用例：测试团队正在编写，预计本周五完成\n\n下一步行动：\n- 张三负责完成后端问题修复\n- 李四协调前端和测试的对接\n- 周五下午 3 点进行联合调试`,
            `客户沟通会议纪要：\n\n客户提出了以下需求变更：\n1. 需要在首页增加数据可视化仪表盘\n2. 报表导出功能要支持 Excel 和 PDF 两种格式\n3. 用户权限管理需要更细粒度的控制\n\n我们的回应：\n- 第一个需求可以接受，预计增加 5 个工作日\n- 第二个需求需要评估技术可行性\n- 第三个需求建议放到二期开发\n\n待办事项：\n- 王五准备技术评估报告\n- 赵六更新项目计划书\n- 下周三前给客户正式回复`
        ];

        const randomText = mockTranscriptions[Math.floor(Math.random() * mockTranscriptions.length)];
        
        // 生成会议纪要
        const summary = this.generateSummary(randomText);
        
        // 提取任务
        const tasks = this.extractTasks(randomText);
        
        // 更新转录记录
        transcription.status = 'completed';
        transcription.text = randomText;
        transcription.summary = summary;
        transcription.tasks = tasks;
        
        Storage.save(Storage.KEYS.TRANSCRIPTIONS, AppState.transcriptions);
        
        // 添加任务到任务列表
        tasks.forEach(task => {
            AppState.tasks.push({
                id: Utils.generateId(),
                transcriptionId: transcription.id,
                text: task.text,
                assignee: task.assignee,
                completed: false,
                createdAt: new Date().toISOString()
            });
        });
        Storage.save(Storage.KEYS.TASKS, AppState.tasks);
        
        Utils.showToast('转录完成');
        UI.renderTranscriptions();
        UI.renderTasks();
    },

    generateSummary(text) {
        // 简单的摘要生成逻辑
        const lines = text.split('\n').filter(line => line.trim());
        const keyPoints = [];
        
        lines.forEach(line => {
            if (line.includes('：') || line.includes('讨论') || line.includes('决定') || 
                line.includes('计划') || line.includes('需要') || line.match(/^\d+\./)) {
                keyPoints.push(line.trim());
            }
        });
        
        return {
            overview: '本次会议主要讨论了项目进展、技术方案和资源协调等议题。',
            keyPoints: keyPoints.slice(0, 6),
            decisions: keyPoints.filter(p => p.includes('决定') || p.includes('同意') || p.includes('确认')),
            nextSteps: keyPoints.filter(p => p.includes('下一步') || p.includes('待办') || p.includes('行动'))
        };
    },

    extractTasks(text) {
        const tasks = [];
        const lines = text.split('\n');
        
        lines.forEach(line => {
            // 匹配 "姓名 + 负责/完成/处理" 的模式
            const assigneeMatch = line.match(/([\u4e00-\u9fa5]{2,4})(?:负责|完成|处理|准备|协调|进行)/);
            if (assigneeMatch) {
                tasks.push({
                    text: line.trim().replace(/^[\-\*\d\.\s]+/, ''),
                    assignee: assigneeMatch[1]
                });
            }
            // 匹配 "待办/行动/任务" 相关的行
            else if (line.includes('待办') || line.includes('行动') || line.includes('任务') || 
                     line.includes('TODO') || line.match(/^-\s/)) {
                tasks.push({
                    text: line.trim().replace(/^[\-\*\d\.\s]+/, ''),
                    assignee: null
                });
            }
        });
        
        return tasks;
    },

    handleFileUpload(file) {
        if (!file || !file.type.startsWith('audio/')) {
            Utils.showToast('请选择有效的音频文件', 'error');
            return;
        }

        const recording = {
            id: Utils.generateId(),
            title: file.name.replace(/\.[^/.]+$/, ''),
            blob: file,
            url: URL.createObjectURL(file),
            duration: 0, // 无法预先知道时长
            size: file.size,
            createdAt: new Date().toISOString()
        };

        const recordingMeta = {
            id: recording.id,
            title: recording.title,
            duration: recording.duration,
            size: recording.size,
            createdAt: recording.createdAt
        };

        AppState.recordings.unshift(recordingMeta);
        Storage.save(Storage.KEYS.RECORDINGS, AppState.recordings);
        this.saveAudioBlob(recording.id, file);

        Utils.showToast('音频文件已上传');
        this.transcribeRecording(recording.id, file);
        UI.renderRecordings();
    }
};

// ==================== UI 渲染 ====================
const UI = {
    init() {
        this.loadData();
        this.bindEvents();
        this.renderRecordings();
        this.renderTranscriptions();
        this.renderTasks();
    },

    loadData() {
        AppState.recordings = Storage.load(Storage.KEYS.RECORDINGS);
        AppState.transcriptions = Storage.load(Storage.KEYS.TRANSCRIPTIONS);
        AppState.tasks = Storage.load(Storage.KEYS.TASKS);
    },

    bindEvents() {
        // 导航切换
        DOM.navItems.forEach(item => {
            item.addEventListener('click', (e) => {
                e.preventDefault();
                const view = item.dataset.view;
                this.switchView(view);
            });
        });

        // 录音控制
        DOM.recordBtn.addEventListener('click', () => Recorder.start());
        DOM.pauseBtn.addEventListener('click', () => Recorder.pause());
        DOM.stopBtn.addEventListener('click', () => Recorder.stop());

        // 文件上传
        DOM.audioUpload.addEventListener('change', (e) => {
            if (e.target.files.length > 0) {
                Recorder.handleFileUpload(e.target.files[0]);
                e.target.value = '';
            }
        });

        // 模态框关闭
        DOM.closePlayerModal.addEventListener('click', () => this.closeModal(DOM.playerModal));
        DOM.closeTranscriptionModal.addEventListener('click', () => this.closeModal(DOM.transcriptionModal));
        DOM.closeSummaryModal.addEventListener('click', () => this.closeModal(DOM.summaryModal));
        DOM.cancelConfirm.addEventListener('click', () => this.closeModal(DOM.confirmModal));

        // 点击模态框背景关闭
        [DOM.playerModal, DOM.transcriptionModal, DOM.summaryModal, DOM.confirmModal].forEach(modal => {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) this.closeModal(modal);
            });
        });

        // 标签页切换
        DOM.tabBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                const tab = btn.dataset.tab;
                this.switchTab(tab);
            });
        });

        // 清空数据
        DOM.clearDataBtn.addEventListener('click', () => this.showConfirmDialog(
            '清空所有数据',
            '确定要清空所有录音、转录和任务数据吗？此操作不可恢复。',
            () => this.clearAllData()
        ));

        // 确认操作
        DOM.confirmAction.addEventListener('click', () => {
            if (this.confirmCallback) {
                this.confirmCallback();
                this.confirmCallback = null;
            }
            this.closeModal(DOM.confirmModal);
        });
    },

    switchView(viewName) {
        AppState.currentView = viewName;
        
        // 更新导航状态
        DOM.navItems.forEach(item => {
            item.classList.toggle('active', item.dataset.view === viewName);
        });

        // 更新视图显示
        DOM.views.forEach(view => {
            view.classList.toggle('active', view.id === `${viewName}-view`);
        });

        // 刷新对应视图的数据
        if (viewName === 'recordings') this.renderRecordings();
        else if (viewName === 'transcriptions') this.renderTranscriptions();
        else if (viewName === 'tasks') this.renderTasks();
    },

    switchTab(tabName) {
        DOM.tabBtns.forEach(btn => {
            btn.classList.toggle('active', btn.dataset.tab === tabName);
        });

        DOM.tabContents.forEach(content => {
            content.classList.toggle('active', content.id === `${tabName}Tab`);
        });
    },

    renderRecordings() {
        if (AppState.recordings.length === 0) {
            DOM.recordingsList.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-microphone-slash"></i>
                    <h3>暂无录音</h3>
                    <p>开始录制或上传您的第一个音频文件</p>
                </div>
            `;
            return;
        }

        DOM.recordingsList.innerHTML = AppState.recordings.map(recording => `
            <div class="recording-item" data-id="${recording.id}">
                <div class="recording-icon">
                    <i class="fas fa-music"></i>
                </div>
                <div class="recording-info">
                    <div class="recording-title">${recording.title}</div>
                    <div class="recording-meta">
                        ${Utils.formatDate(recording.createdAt)} · 
                        ${recording.duration > 0 ? Utils.formatDuration(recording.duration) : '未知时长'} · 
                        ${Utils.formatFileSize(recording.size)}
                    </div>
                </div>
                <div class="recording-actions">
                    <button class="btn-icon" onclick="UI.playRecording('${recording.id}')" title="播放">
                        <i class="fas fa-play"></i>
                    </button>
                    <button class="btn-icon" onclick="UI.viewTranscription('${recording.id}')" title="查看转录">
                        <i class="fas fa-file-alt"></i>
                    </button>
                    <button class="btn-icon danger" onclick="UI.deleteRecording('${recording.id}')" title="删除">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
        `).join('');
    },

    renderTranscriptions() {
        if (AppState.transcriptions.length === 0) {
            DOM.transcriptionsList.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-file-lines"></i>
                    <h3>暂无转录</h3>
                    <p>录音完成后会自动生成转录文本</p>
                </div>
            `;
            return;
        }

        DOM.transcriptionsList.innerHTML = AppState.transcriptions.map(transcription => {
            const statusClass = transcription.status;
            const statusText = {
                'pending': '等待中',
                'processing': '转录中...',
                'completed': '已完成'
            }[transcription.status];

            return `
                <div class="transcription-item" onclick="UI.openTranscriptionModal('${transcription.id}')">
                    <div class="transcription-header">
                        <div class="transcription-title">转录 #${transcription.id.slice(-6)}</div>
                        <span class="transcription-status ${statusClass}">${statusText}</span>
                    </div>
                    <div class="transcription-preview">
                        ${transcription.text || '正在处理中，请稍候...'}
                    </div>
                    <div class="transcription-meta">
                        <span><i class="fas fa-calendar"></i> ${Utils.formatDate(transcription.createdAt)}</span>
                        ${transcription.tasks.length > 0 ? `<span><i class="fas fa-tasks"></i> ${transcription.tasks.length} 个任务</span>` : ''}
                    </div>
                </div>
            `;
        }).join('');
    },

    renderTasks() {
        // 总任务面板 - 所有任务
        const totalTasks = AppState.tasks;
        DOM.totalTaskCount.textContent = totalTasks.length;

        if (totalTasks.length === 0) {
            DOM.totalTasksList.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-clipboard-check"></i>
                    <p>暂无任务</p>
                </div>
            `;
        } else {
            DOM.totalTasksList.innerHTML = totalTasks.map(task => this.renderTaskItem(task)).join('');
        }

        // 个人任务面板 - 有指派人的任务或未完成的任务
        const personalTasks = AppState.tasks.filter(t => t.assignee || !t.completed);
        DOM.personalTaskCount.textContent = personalTasks.length;

        if (personalTasks.length === 0) {
            DOM.personalTasksList.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-user-check"></i>
                    <p>暂无个人任务</p>
                </div>
            `;
        } else {
            DOM.personalTasksList.innerHTML = personalTasks.map(task => this.renderTaskItem(task)).join('');
        }
    },

    renderTaskItem(task) {
        return `
            <div class="task-item ${task.completed ? 'completed' : ''}" data-id="${task.id}">
                <div class="task-checkbox ${task.completed ? 'checked' : ''}" onclick="UI.toggleTask('${task.id}')">
                    ${task.completed ? '<i class="fas fa-check"></i>' : ''}
                </div>
                <div class="task-content">
                    <div class="task-text">${task.text}</div>
                    <div class="task-meta">
                        ${task.assignee ? `<span class="task-assignee"><i class="fas fa-user"></i> ${task.assignee}</span>` : ''}
                        <span class="task-source">来自转录 #${task.transcriptionId.slice(-6)}</span>
                    </div>
                </div>
                <div class="task-delete" onclick="UI.deleteTask('${task.id}')">
                    <i class="fas fa-times"></i>
                </div>
            </div>
        `;
    },

    playRecording(recordingId) {
        const recording = AppState.recordings.find(r => r.id === recordingId);
        if (!recording) return;

        const blob = Recorder.getAudioBlob(recordingId);
        if (!blob) {
            Utils.showToast('音频文件不可用', 'error');
            return;
        }

        DOM.playerTitle.textContent = recording.title;
        DOM.audioPlayer.src = URL.createObjectURL(blob);
        DOM.playerInfo.innerHTML = `
            <p>录制时间: ${Utils.formatDate(recording.createdAt)}</p>
            <p>文件大小: ${Utils.formatFileSize(recording.size)}</p>
        `;

        this.openModal(DOM.playerModal);
        DOM.audioPlayer.play();
    },

    viewTranscription(recordingId) {
        const transcription = AppState.transcriptions.find(t => t.recordingId === recordingId);
        if (!transcription) {
            Utils.showToast('暂无转录内容', 'error');
            return;
        }
        this.openTranscriptionModal(transcription.id);
    },

    openTranscriptionModal(transcriptionId) {
        const transcription = AppState.transcriptions.find(t => t.id === transcriptionId);
        if (!transcription) return;

        DOM.transcriptionTitle.textContent = `转录详情 #${transcription.id.slice(-6)}`;
        
        // 转录文本
        DOM.transcriptText.textContent = transcription.text || '正在处理中...';
        
        // 会议纪要
        if (transcription.summary) {
            DOM.summaryText.innerHTML = `
                <div class="summary-container">
                    <div class="summary-section">
                        <h4>会议概述</h4>
                        <p>${transcription.summary.overview}</p>
                    </div>
                    <div class="summary-section">
                        <h4>关键要点</h4>
                        <ul>
                            ${transcription.summary.keyPoints.map(p => `<li>${p}</li>`).join('')}
                        </ul>
                    </div>
                    ${transcription.summary.decisions.length > 0 ? `
                        <div class="summary-section">
                            <h4>决议事项</h4>
                            <ul>
                                ${transcription.summary.decisions.map(d => `<li>${d}</li>`).join('')}
                            </ul>
                        </div>
                    ` : ''}
                    ${transcription.summary.nextSteps.length > 0 ? `
                        <div class="summary-section">
                            <h4>后续行动</h4>
                            <ul>
                                ${transcription.summary.nextSteps.map(s => `<li>${s}</li>`).join('')}
                            </ul>
                        </div>
                    ` : ''}
                </div>
            `;
        } else {
            DOM.summaryText.innerHTML = '<p>正在生成会议纪要...</p>';
        }
        
        // 提取的任务
        if (transcription.tasks && transcription.tasks.length > 0) {
            DOM.extractedTasks.innerHTML = transcription.tasks.map((task, index) => `
                <div class="extracted-task-item">
                    <i class="fas fa-check-square" style="color: var(--primary-color);"></i>
                    <div>
                        <div>${task.text}</div>
                        ${task.assignee ? `<small style="color: var(--text-muted);">负责人: ${task.assignee}</small>` : ''}
                    </div>
                </div>
            `).join('');
        } else {
            DOM.extractedTasks.innerHTML = '<p style="color: var(--text-muted);">未提取到任务</p>';
        }

        // 重置到第一个标签页
        this.switchTab('transcript');
        this.openModal(DOM.transcriptionModal);
    },

    deleteRecording(recordingId) {
        this.showConfirmDialog(
            '删除录音',
            '确定要删除这个录音吗？相关的转录和任务也会被删除。',
            () => {
                // 删除录音
                AppState.recordings = AppState.recordings.filter(r => r.id !== recordingId);
                Storage.save(Storage.KEYS.RECORDINGS, AppState.recordings);
                
                // 删除相关转录
                const transcriptionIds = AppState.transcriptions
                    .filter(t => t.recordingId === recordingId)
                    .map(t => t.id);
                AppState.transcriptions = AppState.transcriptions.filter(t => t.recordingId !== recordingId);
                Storage.save(Storage.KEYS.TRANSCRIPTIONS, AppState.transcriptions);
                
                // 删除相关任务
                AppState.tasks = AppState.tasks.filter(t => !transcriptionIds.includes(t.transcriptionId));
                Storage.save(Storage.KEYS.TASKS, AppState.tasks);
                
                // 删除音频 blob
                if (window.audioBlobs) {
                    delete window.audioBlobs[recordingId];
                }
                
                this.renderRecordings();
                this.renderTranscriptions();
                this.renderTasks();
                Utils.showToast('录音已删除');
            }
        );
    },

    toggleTask(taskId) {
        const task = AppState.tasks.find(t => t.id === taskId);
        if (task) {
            task.completed = !task.completed;
            Storage.save(Storage.KEYS.TASKS, AppState.tasks);
            this.renderTasks();
        }
    },

    deleteTask(taskId) {
        this.showConfirmDialog(
            '删除任务',
            '确定要删除这个任务吗？',
            () => {
                AppState.tasks = AppState.tasks.filter(t => t.id !== taskId);
                Storage.save(Storage.KEYS.TASKS, AppState.tasks);
                this.renderTasks();
                Utils.showToast('任务已删除');
            }
        );
    },

    showConfirmDialog(title, message, callback) {
        DOM.confirmTitle.textContent = title;
        DOM.confirmMessage.textContent = message;
        this.confirmCallback = callback;
        this.openModal(DOM.confirmModal);
    },

    openModal(modal) {
        modal.classList.add('active');
        document.body.style.overflow = 'hidden';
    },

    closeModal(modal) {
        modal.classList.remove('active');
        document.body.style.overflow = '';
        
        // 停止音频播放
        if (modal === DOM.playerModal) {
            DOM.audioPlayer.pause();
            DOM.audioPlayer.src = '';
        }
    },

    clearAllData() {
        Storage.clear();
        AppState.recordings = [];
        AppState.transcriptions = [];
        AppState.tasks = [];
        window.audioBlobs = {};
        
        this.renderRecordings();
        this.renderTranscriptions();
        this.renderTasks();
        Utils.showToast('所有数据已清空');
    }
};

// ==================== 初始化 ====================
document.addEventListener('DOMContentLoaded', () => {
    UI.init();
});
