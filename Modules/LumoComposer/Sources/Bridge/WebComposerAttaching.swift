protocol WebComposerAttaching {
    /// Set up communication with the WebView
    ///
    /// Must be called before using other bridge methods.
    ///
    /// - Parameter webView: The WKWebView to communicate with
    func attach(to webView: WebViewProtocol)
}
