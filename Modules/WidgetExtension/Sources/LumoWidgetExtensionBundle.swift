//
//  LumoWidgetExtensionBundle.swift
//  LumoWidgetExtension
//
//  Created by Eamonn Maguire on 17.03.2025.

import WidgetKit
import SwiftUI
import os.log

class WidgetBundleLogger {
    static let shared = WidgetBundleLogger()
    private let logger = Logger(subsystem: "me.proton.lumo.widget.bundle", category: "WidgetBundle")
    
    private init() {}
    
    func log(_ message: String) {
        logger.log("\(message)")
    }
}

// We need to use conditional compilation for the entry point
#if canImport(WidgetKit) && canImport(SwiftUI)
@main
struct LumoWidgetExtensionBundle: WidgetBundle {
    init() {
        WidgetBundleLogger.shared.log("LumoWidgetExtensionBundle initialized")
    }
    
    var body: some Widget {
        // The contained widget will handle iOS version compatibility
        LumoWidgetExtension()
    }
}
#endif
