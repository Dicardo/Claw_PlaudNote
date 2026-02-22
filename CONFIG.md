# PlaudNote 配置指南

## 快速开始

### 1. 获取 OpenAI API Key

1. 访问 [OpenAI Platform](https://platform.openai.com/)
2. 注册或登录账号
3. 点击左侧菜单 "API Keys"
4. 点击 "Create new secret key"
5. 复制生成的密钥（注意：密钥只显示一次）

### 2. 配置 API Key

#### 推荐方式：Xcode 环境变量

1. 在 Xcode 中打开项目
2. 点击顶部菜单栏的 Product → Scheme → Edit Scheme
3. 在左侧选择 "Run"
4. 选择顶部的 "Arguments" 标签
5. 在 "Environment Variables" 区域点击 "+" 添加：
   - Name: `OPENAI_API_KEY`
   - Value: `sk-xxxxxxxxxxxxxxxx` (你的 API Key)
6. 关闭窗口，运行项目

#### 替代方式：修改 Config.swift（仅开发测试）

```swift
// PlaudNote/Utils/Config.swift

// 取消注释并填入你的 API Key
private static let hardcodedAPIKey = "sk-your-api-key-here"

// 然后修改 openAIAPIKey 属性：
static var openAIAPIKey: String? {
    // 优先使用硬编码的 key
    if !hardcodedAPIKey.isEmpty {
        return hardcodedAPIKey
    }
    // ... 其他方式
}
```

#### 替代方式：Info.plist

1. 在 Xcode 中打开 `PlaudNote/Info.plist`
2. 添加一行：
   - Key: `OPENAI_API_KEY`
   - Type: `String`
   - Value: 你的 API Key

### 3. 配置麦克风权限

应用已经配置了麦克风权限描述（`NSMicrophoneUsageDescription`），首次录音时会自动弹出权限请求。

如果需要修改权限描述，编辑 `PlaudNote/Info.plist` 中的：
```xml
<key>NSMicrophoneUsageDescription</key>
<string>PlaudNote 需要访问麦克风来录制音频</string>
```

## 真机运行配置

### 1. 修改 Bundle Identifier

1. 在 Xcode 中选中项目
2. 选择 TARGETS → PlaudNote → General
3. 修改 Bundle Identifier 为唯一值，例如：
   - `com.yourname.PlaudNote`

### 2. 配置签名

1. 选择 TARGETS → PlaudNote → Signing & Capabilities
2. 在 Team 下拉框中选择你的 Apple ID
   - 如果没有，点击 "Add Account..." 登录
3. 确保 "Automatically manage signing" 已勾选

### 3. 连接设备运行

1. 使用 USB 连接 iPhone/iPad
2. 在 Xcode 顶部工具栏选择你的设备
3. 点击运行按钮（⌘+R）
4. 首次运行需要在设备上信任开发者证书：
   - 设置 → 通用 → VPN与设备管理 → 信任你的 Apple ID

## API 费用说明

### Whisper API 定价
- $0.006 / 分钟（按音频时长计费）
- 例如：10 分钟的录音转录费用约 $0.06

### GPT API 定价（GPT-3.5-turbo）
- 输入：$0.0015 / 1K tokens
- 输出：$0.002 / 1K tokens
- 例如：一篇会议纪要生成约 $0.01-0.03

### 费用控制建议
1. 在 OpenAI 控制台设置使用限额
2. 定期检查用量统计
3. 开发测试时使用短音频文件

## 常见问题

### Q: 转录失败，提示 "未配置 OpenAI API Key"
A: 检查 API Key 是否正确配置，确保环境变量或 Config.swift 中的 key 有效。

### Q: 录音时没有声音波形
A: 检查麦克风权限是否已授权，可在设备的设置 → 隐私与安全 → 麦克风中查看。

### Q: 无法播放录音
A: 确保录音文件存在且未损坏，检查 AudioPlayer 的 prepare 方法是否成功调用。

### Q: 真机运行提示 "无法安装"
A: 检查 Bundle Identifier 是否唯一，Team 是否正确配置，设备是否信任开发者证书。

## 自定义配置

### 修改转录语言
编辑 `Config.swift`：
```swift
static let whisperLanguage: String? = "zh" // 指定中文，或设为 nil 自动检测
```

### 修改 GPT 模型
编辑 `Config.swift`：
```swift
static let gptModel = "gpt-4" // 使用 GPT-4 获得更好效果（费用更高）
```

### 修改录音质量
编辑 `AudioRecorder.swift` 中的 settings：
```swift
let settings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
    AVSampleRateKey: 48000,  // 提高采样率
    AVNumberOfChannelsKey: 2, // 立体声
    AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
]
```
