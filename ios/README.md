# 玄枢阁 iOS 工程

这是一个 SwiftUI + WKWebView 的 iOS 16+ 工程。网页、字体、图标和交互全部离线内置；赛事由 `URLSession` 原生请求官方接口，不需要 Node.js、本地端口或 `启动.bat`。

## 工程结构

- `Xuanshu.xcodeproj`：可直接由 Xcode 15 打开。
- `Xuanshu/XuanshuWebView.swift`：WKWebView 容器和原生取数桥。
- `Xuanshu/Assets.xcassets`：App 图标与强调色。
- 根目录 `index.html`：网页界面，由 Xcode 作为资源文件直接打包。
- `build-unsigned-ipa.sh`：在 macOS 上生成供签名工具导入的未签名 IPA。

## 使用 Xcode 构建

1. 将整个项目目录复制到 macOS。
2. 打开 `ios/Xuanshu.xcodeproj`。
3. 在 Target → Signing & Capabilities 中选择自己的 Team，或保持 Automatic Signing 交给签名工具配置。
4. Bundle Identifier 默认为 `com.xuanshu.jingcai`，与现有工具冲突时可以修改。
5. 选择自己的 iPhone 后 Run，或使用 Product → Archive。

## 生成未签名 IPA

```bash
cd ios
chmod +x build-unsigned-ipa.sh
./build-unsigned-ipa.sh
```

产物位于：

```text
ios/build/Xuanshu-unsigned.ipa
```

将该 IPA 导入你现有的签名工具，替换证书、Bundle ID 和描述文件后安装。

如果没有本机 macOS，也可以将项目放入 GitHub 仓库，在 Actions 中手动运行 `Build unsigned iOS IPA` 工作流，下载自动构建的未签名 IPA。

## 原生取数桥

网页通过 `window.webkit.messageHandlers.xuanshuNative` 请求赛事，Swift 使用 `URLSession` 获取官方 JSON，再异步回传给页面。这样绕开了 iOS WKWebView 的跨域限制，同时保留网页端原有的安全转义与缓存降级。

仅显示一个最终主推组合，不再生成或展示副卦。

> 本项目仅供玄学娱乐，不构成投注建议。
