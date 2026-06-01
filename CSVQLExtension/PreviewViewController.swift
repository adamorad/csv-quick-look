import Cocoa
import QuickLookUI
import WebKit

class PreviewViewController: NSViewController, QLPreviewingController {

    private var webView: WKWebView!
    private var pendingResult: CSVParseResult?
    private var pendingIsDark: Bool = false
    private var pendingFileName: String = ""

    override func loadView() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        self.view = webView
    }

    // MARK: - QLPreviewingController

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { handler(nil); return }

            guard let data = try? Data(contentsOf: url) else {
                handler(PreviewError.unreadableFile); return
            }
            guard let text = CSVParser.decode(data) else {
                handler(PreviewError.unsupportedEncoding); return
            }

            let storedMax = UserDefaults.standard.integer(forKey: "maxRows")
            let maxRows = storedMax > 0 ? storedMax : 100_000
            let autoDetect = UserDefaults.standard.object(forKey: "autoDetectDelimiter") as? Bool ?? true
            let delimiter: Character? = autoDetect ? nil : ","
            let result = CSVParser.parse(text, delimiter: delimiter, maxRows: maxRows)

            DispatchQueue.main.async {
                let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                self.pendingResult = result
                self.pendingIsDark = isDark
                self.pendingFileName = url.lastPathComponent
                self.loadHTML()
                handler(nil)
            }
        }
    }

    // MARK: - HTML Loading

    private func loadHTML() {
        guard
            let resourceURL = Bundle.main.resourceURL,
            let htmlURL = Bundle.main.url(forResource: "preview", withExtension: "html")
        else { return }

        webView.loadFileURL(htmlURL, allowingReadAccessTo: resourceURL)
    }

    private func injectData() {
        guard
            let result = pendingResult,
            let headersJSON = encode(result.headers),
            let rowsJSON = encode(result.rows),
            let fileNameJSON = encode(pendingFileName)
        else { return }

        let isDark = pendingIsDark ? "true" : "false"
        let js = "initTable(\(headersJSON), \(rowsJSON), \(result.totalRowCount), \(isDark), \(fileNameJSON));"
        webView.evaluateJavaScript(js)
    }

    private func encode<T: Encodable>(_ value: T) -> String? {
        guard
            let data = try? JSONEncoder().encode(value),
            let str = String(data: data, encoding: .utf8)
        else { return nil }
        return str
    }
}

// MARK: - WKNavigationDelegate

extension PreviewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        injectData()
        pendingResult = nil
    }
}

// MARK: - Errors

private enum PreviewError: LocalizedError {
    case unreadableFile, unsupportedEncoding

    var errorDescription: String? {
        switch self {
        case .unreadableFile:     return "Could not read the file."
        case .unsupportedEncoding: return "Unsupported text encoding."
        }
    }
}
