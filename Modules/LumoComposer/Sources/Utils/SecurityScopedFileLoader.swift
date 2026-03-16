import Foundation

func securityScopedFileLoader(url: URL) throws -> Data {
    guard url.startAccessingSecurityScopedResource() else {
        throw CocoaError(.fileReadNoPermission)
    }
    defer { url.stopAccessingSecurityScopedResource() }
    return try Data(contentsOf: url)
}
