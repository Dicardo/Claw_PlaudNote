# PlaudNote API Key 配置说明

## 已配置的 Key

### ✅ Kimi API Key
- **位置**: `Info.plist` 中的 `KIMI_API_KEY`
- **状态**: 已配置
- **用途**: AI 摘要功能（调用 Kimi API 生成会议纪要）
- **配置方式**: 直接硬编码在 Info.plist 中

## 需要用户配置的 Key

### ⚠️ OpenAI API Key (用于 Whisper)
- **位置**: 环境变量 `OPENAI_API_KEY`
- **状态**: 未配置（需要用户自行设置）
- **用途**: 语音转文字功能（调用 OpenAI Whisper API）
- **配置方式**: 
  1. 在 Xcode 的 Scheme 中设置环境变量 `OPENAI_API_KEY`
  2. 或在 Build Settings 中设置 User-Defined 变量
  3. 或在运行时通过设置界面输入

## 配置方法

### 在 Xcode Scheme 中设置环境变量

1. 打开 Xcode
2. 点击 Product → Scheme → Edit Scheme
3. 选择 Run → Arguments → Environment Variables
4. 添加变量:
   - Name: `OPENAI_API_KEY`
   - Value: `your-openai-api-key-here`

### 在 Build Settings 中设置

1. 打开项目设置
2. 选择 Target → Build Settings
3. 添加 User-Defined Setting:
   - Key: `OPENAI_API_KEY`
   - Value: `your-openai-api-key-here`

## 安全提示

⚠️ **重要**: 不要将 API Key 提交到代码仓库！

- Kimi API Key 当前硬编码在 Info.plist 中，仅用于开发测试
- 生产环境建议：
  - 使用环境变量
  - 或从安全存储（Keychain）读取
  - 或从后端服务器动态获取

## 验证配置

运行应用后，可以在控制台查看 API Key 是否正确加载：

```swift
// 在 App 启动时检查
if let kimiKey = Config.kimiAPIKey {
    print("✅ Kimi API Key 已配置")
} else {
    print("❌ Kimi API Key 未配置")
}
```
