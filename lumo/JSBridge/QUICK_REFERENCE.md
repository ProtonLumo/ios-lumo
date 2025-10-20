# Quick Reference - JavaScript Bridge

## 🚀 Common Operations

### Insert Prompt
```swift
Task {
    await jsCoordinator.insertPrompt("Hello AI!")
}
```

### Insert Voice Transcription
```swift
Task {
    let result = await jsCoordinator.insertPrompt(transcribedText, editorType: .tiptap)
    
    switch result {
    case .success:
        // Continue
    case .failure(let error):
        // Handle error
    }
}
```

### Get Subscriptions
```swift
Task {
    let result = await jsCoordinator.getSubscriptions()
    
    if case .success(let data) = result,
       let subscriptions = data as? [[String: Any]] {
        // Use subscriptions
    }
}
```

### Read Theme
```swift
Task {
    let result = await jsCoordinator.readTheme()
    
    if case .success(let data) = result,
       let dict = data as? [String: Any],
       let theme = dict["theme"] as? String {
        // Use theme
    }
}
```

### Setup Initial Scripts
```swift
Task {
    await jsCoordinator.setupInitialScripts()
}
```

### Cleanup
```swift
Task {
    await jsCoordinator.cleanup()
}
```

---

## 📋 Available Commands

### Prompt Operations
- `.insertPrompt(text: String, editorType: EditorType)`
- `.clearPrompt`

### Payment Operations
- `.getSubscriptions`
- `.restorePurchases`
- `.cancelSubscription`
- `.openPaymentSheet(payload: [String: Any])`

### Theme Operations
- `.readTheme`
- `.updateTheme(theme: String)`
- `.setupThemeListener`

### Utility Operations
- `.hideYourPlan`
- `.checkElementExists(selector: String)`
- `.simulateGarbageCollection`
- `.clearHistory`

### Setup Operations
- `.initialSetup`
- `.setupMessageHandlers`
- `.setupPromotionHandler`
- `.setupVoiceEntry`

---

## 🎯 Error Handling

```swift
let result = await jsCoordinator.insertPrompt("Hello")

switch result {
case .success:
    print("✅ Success!")
    
case .failure(let error):
    print("❌ Error: \(error.errorDescription ?? "")")
    
    if error.isRecoverable {
        // Retry makes sense
    }
}
```

---

## 🔧 Advanced Usage

### Batch Operations
```swift
let commands: [JSCommand] = [
    .initialSetup,
    .setupThemeListener,
    .hideYourPlan
]

let results = await jsCoordinator.executeBatch(commands)
print("✅ \(results.filter { $0.isSuccess }.count)/\(commands.count) succeeded")
```

### With Retry
```swift
let result = await jsCoordinator.insertPrompt("Hello", retryCount: 2)
```

### Custom Command
```swift
let result = await jsCoordinator.execute(.checkElementExists(selector: ".my-class"))
```

---

## 📝 Integration Points

### ContentView Setup
```swift
@StateObject private var jsCoordinator = WebViewCoordinator()

WebView(url: URL.lumoBase!,
        isReady: $webViewReady,
        jsCoordinator: jsCoordinator,
        // ...
)

.onChange(of: webViewReady) { isReady in
    if isReady {
        jsCoordinator.markReady()
        Task {
            await jsCoordinator.setupInitialScripts()
        }
    }
}
```

### Widget Deep-Link
```swift
.onReceive(NotificationCenter.default.publisher(for: .init("LumoPromptReceived"))) { notification in
    if let prompt = notification.userInfo?["prompt"] as? String {
        Task {
            await jsCoordinator.insertPrompt(prompt)
        }
    }
}
```

### Voice Transcription
```swift
Task {
    let result = await jsCoordinator.insertPrompt(transcribedText, editorType: .tiptap)
    
    switch result {
    case .success:
        await observeTextInsertion()
    case .failure:
        isInsertingText = false
        isSubmittingSpeech = false
    }
}
```

---

## 🐛 Debugging

### Check Coordinator Status
```swift
print("Ready: \(jsCoordinator.isReady)")
print("Last Error: \(jsCoordinator.lastError?.errorDescription ?? "none")")
```

### Enable Logging
All operations automatically log via `Logger.shared`:
- 🚀 Command execution
- ✅ Successes
- ❌ Failures
- 🔄 Retries

---

## ⚠️ Common Mistakes

### ❌ DON'T: Call before marking ready
```swift
// Wrong - coordinator not configured yet
await jsCoordinator.insertPrompt("Hello")
```

### ✅ DO: Mark ready when WebView loads
```swift
.onChange(of: webViewReady) { isReady in
    if isReady {
        jsCoordinator.markReady() // Important!
    }
}
```

---

### ❌ DON'T: Forget Task wrapper
```swift
// Wrong - await outside Task
await jsCoordinator.insertPrompt("Hello")
```

### ✅ DO: Wrap in Task
```swift
Task {
    await jsCoordinator.insertPrompt("Hello")
}
```

---

### ❌ DON'T: Ignore errors
```swift
await jsCoordinator.insertPrompt("Hello")
// Did it work? 🤷
```

### ✅ DO: Handle results
```swift
let result = await jsCoordinator.insertPrompt("Hello")

switch result {
case .success:
    // Continue
case .failure(let error):
    // Handle error
}
```

---

## 📚 More Info

- Full docs: `/lumo/JSBridge/README.md`
- Migration guide: `/lumo/JSBridge/MIGRATION_GUIDE.md`
- Examples: `/lumo/JSBridge/BEFORE_AFTER_EXAMPLE.md`
- Summary: `/REFACTOR_SUMMARY.md`

---

## 💡 Pro Tips

1. **Automatic Queueing** - Don't check `isReady`, coordinator handles it!
2. **Type Safety** - Let the compiler catch errors with `JSCommand` enum
3. **Batch Operations** - Use `executeBatch()` for multiple commands
4. **Structured Errors** - Check `error.isRecoverable` for retry logic
5. **Clean Code** - Use convenience methods like `insertPrompt()` instead of `execute()`

---

**Happy Coding! 🚀**

