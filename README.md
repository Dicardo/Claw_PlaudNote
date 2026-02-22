# PlaudNote - iOS AI 录音笔应用

一款对标 Plaud Note 的 AI 录音笔软件，支持录音、语音转文字、AI 摘要生成等功能。

## 功能特性

- 🎙️ **录音功能**: 高质量的音频录制，支持实时波形显示
- 📝 **语音转文字**: 使用 iOS 原生 Speech 框架进行转录，完全免费
- 🤖 **AI 摘要**: 使用 Kimi API 自动生成会议纪要和待办事项
- 🔍 **搜索管理**: 支持按标题和内容搜索录音
- 📱 **简洁 UI**: 商务风格设计，iOS 16+ 原生体验

## 项目结构

```
PlaudNote/
├── PlaudNote/
│   ├── PlaudNoteApp.swift          # 应用入口
│   ├── Info.plist                  # 应用配置
│   ├── Assets.xcassets/            # 资源文件
│   │
│   ├── Models/                     # 数据模型
│   │   └── Recording.swift         # 录音模型
│   │
│   ├── Views/                      # 视图层
│   │   ├── ContentView.swift       # 主界面（录音列表）
│   │   ├── RecordingView.swift     # 录音界面
│   │   └── RecordingDetailView.swift # 录音详情（播放、转录、摘要）
│   │
│   ├── ViewModels/                 # 视图模型
│   │   └── RecordingStore.swift    # 录音数据管理
│   │
│   ├── Services/                   # 服务层
│   │   ├── AudioRecorder.swift     # 音频录制
│   │   ├── AudioPlayer.swift       # 音频播放
│   │   ├── AudioSessionManager.swift # 音频会话管理
│   │   ├── TranscriptionService.swift # iOS Speech 转录服务
│   │   └── SummaryService.swift    # AI 摘要服务（Kimi API）
│   │
│   └── Utils/                      # 工具类
│       ├── Config.swift            # 配置管理
│       └── Extensions.swift        # 扩展方法
│
├── PlaudNote.xcodeproj/            # Xcode 项目文件
└── README.md                       # 项目说明
```

## 配置说明

### 1. API Key 配置

应用需要配置 API Key 来使用 AI 摘要功能：
- **AI 摘要**: Kimi API Key

**注意**: 语音转文字功能使用 iOS 原生 Speech 框架，不需要 API Key，完全免费！

#### Kimi API Key 配置（用于 AI 摘要）

有三种配置方式：

##### 方式一：Info.plist（推荐）

1. 在 Xcode 中打开项目
2. 找到 `Info.plist` 文件
3. 添加键 `KIMI_API_KEY`，值为你的 Kimi API Key

##### 方式二：Xcode 环境变量（开发调试）

1. 在 Xcode 中选择 Product → Scheme → Edit Scheme
2. 选择 Run → Arguments
3. 在 Environment Variables 中添加：
   - Name: `KIMI_API_KEY`
   - Value: 你的 Kimi API Key

##### 方式三：直接修改 Config.swift（不推荐生产环境）

```swift
// Config.swift
private static let hardcodedAPIKey = "sk-xxxxxxxxxxxxxxxx"
```

### 2. 获取 API Key

#### Kimi API Key

1. 访问 [Moonshot AI 开放平台](https://platform.moonshot.cn/)
2. 注册/登录账号
3. 进入 API Keys 页面创建新密钥
4. 复制密钥并配置到应用中

## 运行步骤

### 环境要求

- macOS 12.0+
- Xcode 14.0+
- iOS 16.0+ 设备或模拟器
- Kimi API Key（用于 AI 摘要）

### 运行步骤

1. **克隆/下载项目**
   ```bash
   cd PlaudNote
   ```

2. **打开 Xcode 项目**
   ```bash
   open PlaudNote.xcodeproj
   ```

3. **配置 API Key**
   - 按照上述「配置说明」配置 Kimi API Key

4. **选择目标设备**
   - 连接 iOS 设备，或选择 iPhone 模拟器

5. **运行应用**
   - 点击 Xcode 的 Run 按钮（⌘+R）

### 真机运行注意事项

- 需要 Apple Developer 账号
- 在 Signing & Capabilities 中选择你的 Team
- 修改 Bundle Identifier 为唯一标识

## 使用说明

### 录音

1. 点击首页右上角的 `+` 按钮
2. 点击红色录音按钮开始录音
3. 录音过程中可以看到实时波形
4. 点击停止按钮结束录音
5. 输入录音标题并保存

### 语音转文字

1. 在录音列表中点击录音进入详情
2. 切换到「转录文字」标签
3. 点击「开始转录」按钮
4. 等待转录完成（使用 iOS 原生 Speech 框架，免费且支持中文）

**离线识别**: 在「设置 → 通用 → 键盘 → 听写」中下载语言包后，可在离线状态下使用语音识别。

### 生成会议纪要

1. 确保录音已完成转录
2. 切换到「会议纪要」标签
3. 点击「开始生成」按钮
4. 查看 Kimi AI 生成的会议纪要

### 提取待办事项

1. 确保录音已完成转录
2. 切换到「待办事项」标签
3. 点击「开始提取」按钮
4. 查看 Kimi AI 提取的待办清单

## 技术栈

- **语言**: Swift 5.7+
- **UI 框架**: SwiftUI
- **最低版本**: iOS 16.0
- **音频**: AVFoundation
- **语音识别**: Speech 框架（iOS 原生）
- **网络**: URLSession
- **数据持久化**: UserDefaults + 文件系统

## API 说明

### Speech 框架（iOS 原生）

- 完全免费，无需 API Key
- 支持中文、英文等多种语言
- 支持离线识别（需下载语言包）
- 自动添加标点符号（iOS 16+）

### Kimi API（Moonshot AI）

- 端点: `https://api.moonshot.cn/v1/chat/completions`
- 模型: `kimi-coding/k2p5`
- 用于: 会议纪要生成、待办事项提取

## 扩展开发

### 添加新的 AI 功能

1. 在 `SummaryService.swift` 中添加新方法
2. 使用 `generateWithKimi` 方法调用 Kimi API
3. 在 `RecordingDetailView.swift` 中添加新的标签页

### 更换转录服务

`TranscriptionService.swift` 目前使用 iOS 原生 Speech 框架。如需更换为其他服务（如 Whisper API），可修改 `transcribe` 方法实现。

## 注意事项

1. **API 费用**: 仅 AI 摘要功能使用 Kimi API 按使用量收费，语音转文字完全免费
2. **隐私安全**: 录音文件存储在设备本地，语音识别数据会上传至 Apple 服务器处理
3. **网络要求**: 
   - 语音转文字：首次使用需要联网，下载语言包后支持离线识别
   - AI 摘要功能：需要网络连接
4. **权限要求**: 
   - 麦克风权限：用于录音
   - 语音识别权限：用于语音转文字

## License

MIT License
