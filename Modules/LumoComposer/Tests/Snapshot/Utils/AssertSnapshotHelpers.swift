import SnapshotTesting
import SwiftUI

func assertSnapshotsOnEdgeDevices(
    of view: some View,
    named name: String? = nil,
    drawHierarchyInKeyWindow: Bool = false,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    assertSnapshots(
        matching: UIHostingController(rootView: view),
        on: [("SE-3rd", .iPhone8), ("13-Pro-Max", .iPhone13ProMax)],
        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
        named: name,
        record: recording,
        timeout: timeout,
        file: file,
        testName: testName,
        line: line
    )
}

private func assertSnapshots(
    matching controller: @autoclosure () throws -> UIViewController,
    on configurations: [(String, ViewImageConfig)],
    styles: [UIUserInterfaceStyle] = [.light, .dark],
    drawHierarchyInKeyWindow: Bool,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    configurations.forEach { (configurationName, configuration) in
        let name = [name, configurationName].compactMap { $0 }.joined(separator: "_")

        try? styles.forEach { style in
            let controller = try controller()
            controller.overrideUserInterfaceStyle = style
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

            assertSnapshot(
                of: controller,
                as: .image(
                    on: configuration,
                    drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                    traits: .init(userInterfaceStyle: style)
                ),
                named: suffixedName(name: name, withStyle: style),
                record: recording,
                timeout: timeout,
                file: file,
                testName: testName,
                line: line
            )
        }
    }
}

// MARK: - Private

private func suffixedName(name: String?, withStyle style: UIUserInterfaceStyle) -> String? {
    [name, style.humanReadable]
        .compactMap { $0 }
        .joined(separator: "_")
}

private extension UIUserInterfaceStyle {
    var humanReadable: String {
        switch self {
        case .dark:
            return "dark"
        case .light:
            return "light"
        case .unspecified:
            return "unspecified"
        @unknown default:
            return "unknown"
        }
    }
}
