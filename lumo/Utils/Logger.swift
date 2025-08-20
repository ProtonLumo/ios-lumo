import SwiftUI
import os.log

// MARK: - Logger Class
class Logger {
    // MARK: - Static Properties
    static let shared = Logger()
    static let logsUpdatedNotification = Notification.Name("LoggerLogsUpdated")
    
    // MARK: - Private Properties
    private var logFileURL: URL?
    private let fileManager = FileManager.default
    private let dateFormatter: DateFormatter
    private let queue = DispatchQueue(label: "com.lumo.logger", qos: .utility)
    
    // MARK: - Initialization
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        setupLogFile()
        log("Logger initialized", category: "Logger")
    }
    
    // MARK: - Public Methods
    func log(_ message: String, category: String? = nil) {
        let timestamp = dateFormatter.string(from: Date())
        let categoryPrefix = category != nil ? "[\(category!)]" : ""
        let logMessage = "[\(timestamp)]\(categoryPrefix) \(message)"
        
        print(logMessage)
        
        queue.async { [weak self] in
            self?.writeToFile(logMessage)
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Logger.logsUpdatedNotification, object: nil)
            }
        }
    }
    
    func getLogContents() -> String? {
        guard let logFileURL = logFileURL,
              fileManager.fileExists(atPath: logFileURL.path) else {
            return nil
        }
        
        do {
            return try String(contentsOf: logFileURL, encoding: .utf8)
        } catch {
            print("Failed to read log file: \(error)")
            return nil
        }
    }
    
    func getLogContentsForApp(identifier: String? = nil) -> String? {
        guard let allLogs = getLogContents() else {
            return nil
        }
        
        guard let identifier = identifier else {
            return allLogs
        }
        
        let lines = allLogs.components(separatedBy: .newlines)
        let filteredLines = lines.filter { $0.contains("[\(identifier)]") }
        return filteredLines.joined(separator: "\n")
    }

    @discardableResult
    func clearLogs() -> Bool {
        guard let logFileURL = logFileURL else { return false }
        
        do {
            try "".write(to: logFileURL, atomically: true, encoding: .utf8)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Logger.logsUpdatedNotification, object: nil)
            }
            return true
        } catch {
            print("Failed to clear log file: \(error)")
            return false
        }
    }
    
    func getLogFilePath() -> String? {
        return logFileURL?.path
    }
    
    // MARK: - Private Methods
    private func writeToFile(_ message: String) {
        guard let logFileURL = logFileURL else {
            print("Log file URL not set")
            return
        }
        
        do {
            if !fileManager.fileExists(atPath: logFileURL.path) {
                try "".write(to: logFileURL, atomically: true, encoding: .utf8)
            }
            
            let handle = try FileHandle(forWritingTo: logFileURL)
            handle.seekToEndOfFile()
            if let data = (message + "\n").data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        } catch {
            print("Failed to write to log file: \(error)")
        }
    }
    
    private func setupLogFile() {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to get documents directory")
            return
        }
        
        let logDirectory = documentsDirectory.appendingPathComponent("Logs")
        
        do {
            try fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create log directory: \(error)")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        logFileURL = logDirectory.appendingPathComponent("lumo-\(dateString).log")
        
        if let logFileURL = logFileURL, !fileManager.fileExists(atPath: logFileURL.path) {
            do {
                try "".write(to: logFileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to create log file: \(error)")
            }
        }
    }
} 

