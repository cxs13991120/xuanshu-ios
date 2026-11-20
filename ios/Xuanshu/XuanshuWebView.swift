import SwiftUI
import UIKit
import WebKit

struct XuanshuWebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all

        let bridge = NativeBridge()
        context.coordinator.bridge = bridge
        configuration.userContentController.add(bridge, name: "xuanshuNative")
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: "document.documentElement.classList.add('native-app');",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.keyboardDismissMode = .interactive
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.underPageBackgroundColor = .clear
        webView.allowsBackForwardNavigationGestures = false

        context.coordinator.webView = webView
        bridge.webView = webView

        if let indexURL = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "xuanshuNative")
        coordinator.bridge = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var bridge: NativeBridge?

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url,
                  let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" else {
                decisionHandler(.allow)
                return
            }
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }
    }
}

final class NativeBridge: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?
    private let session: URLSession

    override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 18
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: configuration)
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let payload = message.body as? [String: Any],
              payload["action"] as? String == "fetchMatches",
              let requestID = payload["id"] as? String else {
            return
        }
        Task { @MainActor in
            await fetchMatches(requestID: requestID)
        }
    }

    @MainActor
    private func fetchMatches(requestID: String) async {
        guard let url = URL(string: "https://webapi.sporttery.cn/gateway/jc/football/getMatchCalculatorV1.qry?poolCode=hhad,had&channel=c") else {
            return sendResult(id: requestID, ok: false, body: "", error: "数据地址无效")
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("https://www.sporttery.cn/", forHTTPHeaderField: "Referer")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("zh-CN,zh;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        var lastError: Error?
        for attempt in 0..<2 {
            do {
                let (data, response) = try await session.data(for: request)
                guard data.count <= 5 * 1024 * 1024 else {
                    sendResult(id: requestID, ok: false, body: "", error: "赛事数据超过安全上限")
                    return
                }
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                    sendResult(id: requestID, ok: false, body: "", error: "官方数据返回 HTTP \(code)")
                    return
                }
                guard (try? JSONSerialization.jsonObject(with: data)) != nil,
                      let body = String(data: data, encoding: .utf8) else {
                    sendResult(id: requestID, ok: false, body: "", error: "赛事数据编码或格式异常")
                    return
                }
                sendResult(id: requestID, ok: true, body: body, error: "")
                return
            } catch {
                lastError = error
                if attempt == 0 {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                }
            }
        }
        let detail = lastError?.localizedDescription ?? "未知错误"
        sendResult(id: requestID, ok: false, body: "", error: "赛事数据暂不可达：\(detail)")
    }

    @MainActor
    private func sendResult(id: String, ok: Bool, body: String, error: String) {
        guard let webView else { return }
        let envelope: [String: Any] = [
            "id": id,
            "ok": ok,
            "body": body,
            "error": error
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: envelope) else { return }
        let encoded = data.base64EncodedString()
        webView.evaluateJavaScript("window.__xuanshuNativeResultB64('\(encoded)');") { _, jsError in
            if let jsError {
                print("[Xuanshu native bridge] \(jsError.localizedDescription)")
            }
        }
    }
}
