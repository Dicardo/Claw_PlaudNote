/**
 * PlaudNote 单元测试
 * 使用简单的测试框架
 */

// 测试框架
const TestFramework = {
    tests: [],
    results: {
        passed: 0,
        failed: 0,
        errors: []
    },

    test(name, fn) {
        this.tests.push({ name, fn });
    },

    async run() {
        console.log('🧪 开始运行测试...\n');
        
        for (const { name, fn } of this.tests) {
            try {
                await fn();
                console.log(`✅ ${name}`);
                this.results.passed++;
            } catch (error) {
                console.log(`❌ ${name}`);
                console.log(`   错误: ${error.message}`);
                this.results.failed++;
                this.results.errors.push({ name, error });
            }
        }

        console.log('\n📊 测试结果:');
        console.log(`   通过: ${this.results.passed}`);
        console.log(`   失败: ${this.results.failed}`);
        console.log(`   总计: ${this.tests.length}`);
        
        return this.results;
    },

    // 断言方法
    assertEqual(actual, expected, message) {
        if (actual !== expected) {
            throw new Error(message || `期望 ${expected}, 实际 ${actual}`);
        }
    },

    assertTrue(value, message) {
        if (value !== true) {
            throw new Error(message || `期望 true, 实际 ${value}`);
        }
    },

    assertFalse(value, message) {
        if (value !== false) {
            throw new Error(message || `期望 false, 实际 ${value}`);
        }
    },

    assertNotNull(value, message) {
        if (value === null || value === undefined) {
            throw new Error(message || `值不能为 null 或 undefined`);
        }
    },

    assertArrayLength(array, length, message) {
        if (array.length !== length) {
            throw new Error(message || `数组长度期望 ${length}, 实际 ${array.length}`);
        }
    }
};

// ==================== 测试用例 ====================

// 测试工具函数
TestFramework.test('Utils.generateId 应该生成唯一ID', () => {
    const id1 = Utils.generateId();
    const id2 = Utils.generateId();
    TestFramework.assertNotNull(id1, 'ID 不应为 null');
    TestFramework.assertNotNull(id2, 'ID 不应为 null');
    TestFramework.assertEqual(id1 !== id2, true, '生成的 ID 应该唯一');
});

TestFramework.test('Utils.formatDuration 应该正确格式化时长', () => {
    TestFramework.assertEqual(Utils.formatDuration(0), '00:00:00', '0秒');
    TestFramework.assertEqual(Utils.formatDuration(61), '00:01:01', '61秒');
    TestFramework.assertEqual(Utils.formatDuration(3661), '01:01:01', '3661秒');
    TestFramework.assertEqual(Utils.formatDuration(86399), '23:59:59', '86399秒');
});

TestFramework.test('Utils.formatFileSize 应该正确格式化文件大小', () => {
    TestFramework.assertEqual(Utils.formatFileSize(0), '0 B', '0字节');
    TestFramework.assertEqual(Utils.formatFileSize(1024), '1 KB', '1KB');
    TestFramework.assertEqual(Utils.formatFileSize(1024 * 1024), '1 MB', '1MB');
    TestFramework.assertEqual(Utils.formatFileSize(1536), '1.5 KB', '1.5KB');
});

// 测试存储功能
TestFramework.test('Storage.save 和 load 应该正常工作', () => {
    const testData = [{ id: '1', name: '测试' }];
    Storage.save('test_key', testData);
    const loaded = Storage.load('test_key');
    TestFramework.assertEqual(Array.isArray(loaded), true, '加载的数据应该是数组');
    TestFramework.assertEqual(loaded.length, 1, '数组长度应为1');
    TestFramework.assertEqual(loaded[0].name, '测试', '数据内容应匹配');
    localStorage.removeItem('test_key');
});

TestFramework.test('Storage.load 应该返回默认值', () => {
    const loaded = Storage.load('non_existent_key', []);
    TestFramework.assertEqual(Array.isArray(loaded), true, '应返回默认数组');
    TestFramework.assertEqual(loaded.length, 0, '默认数组应为空');
});

// 测试任务提取功能
TestFramework.test('Recorder.extractTasks 应该正确提取任务', () => {
    const text = `会议记录：
张三负责完成前端页面开发
李四需要准备测试用例
王五协调项目进度`;
    
    const tasks = Recorder.extractTasks(text);
    TestFramework.assertTrue(tasks.length >= 2, '应该提取至少2个任务');
    TestFramework.assertTrue(tasks.some(t => t.assignee === '张三'), '应该包含张三的任务');
});

TestFramework.test('Recorder.extractTasks 应该处理待办事项', () => {
    const text = `待办事项：
- 完成 API 文档
- 更新部署脚本
- 测试新功能`;
    
    const tasks = Recorder.extractTasks(text);
    TestFramework.assertTrue(tasks.length >= 2, '应该提取列表项任务');
});

// 测试摘要生成功能
TestFramework.test('Recorder.generateSummary 应该生成会议纪要', () => {
    const text = `会议讨论：
1. 确定了产品方向
2. 讨论了技术方案
决定使用 React 框架
下一步行动计划已制定`;
    
    const summary = Recorder.generateSummary(text);
    TestFramework.assertNotNull(summary.overview, '应该有概述');
    TestFramework.assertTrue(summary.keyPoints.length > 0, '应该有关键要点');
});

// 测试状态管理
TestFramework.test('AppState 应该有正确的初始状态', () => {
    TestFramework.assertEqual(AppState.isRecording, false, '初始不应在录音');
    TestFramework.assertEqual(AppState.isPaused, false, '初始不应暂停');
    TestFramework.assertEqual(Array.isArray(AppState.recordings), true, 'recordings 应该是数组');
    TestFramework.assertEqual(Array.isArray(AppState.transcriptions), true, 'transcriptions 应该是数组');
    TestFramework.assertEqual(Array.isArray(AppState.tasks), true, 'tasks 应该是数组');
});

// 测试数据持久化
TestFramework.test('数据应该正确保存到 localStorage', () => {
    const testRecording = { id: 'test-1', title: '测试录音' };
    AppState.recordings = [testRecording];
    Storage.save(Storage.KEYS.RECORDINGS, AppState.recordings);
    
    const saved = localStorage.getItem(Storage.KEYS.RECORDINGS);
    TestFramework.assertNotNull(saved, '数据应该保存到 localStorage');
    
    const parsed = JSON.parse(saved);
    TestFramework.assertEqual(parsed[0].title, '测试录音', '保存的数据应该正确');
    
    // 清理
    AppState.recordings = [];
    localStorage.removeItem(Storage.KEYS.RECORDINGS);
});

// ==================== 运行测试 ====================

// 在页面加载完成后运行测试
function runTests() {
    console.log('%c PlaudNote 单元测试 ', 'background: #6366f1; color: white; font-size: 16px; padding: 4px 8px;');
    
    TestFramework.run().then(results => {
        if (results.failed === 0) {
            console.log('%c 所有测试通过! ', 'background: #10b981; color: white;');
        } else {
            console.log('%c 有测试失败 ', 'background: #ef4444; color: white;');
        }
    });
}

// 导出测试函数供手动调用
window.runPlaudNoteTests = runTests;
window.TestFramework = TestFramework;
