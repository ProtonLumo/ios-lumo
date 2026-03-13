import Photos
import PhotosUI
import SwiftUI

protocol PhotosItem {
    var itemIdentifier: String? { get }
    var supportedContentTypes: [UTType] { get }
}

protocol PhotosItemLoading: PhotosItem {
    func loadTransferableData() async throws -> Data?
}

enum PhotoFileNameExtractor {
    /// Returns the original filename of the photo asset if available, otherwise falls back to a UUID-based name
    /// with an extension inferred from the item's supported content types.
    static func fileName(
        from item: PhotosItem,
        assetNameProvider: (String) -> String? = PHAsset.name
    ) -> String {
        guard let identifier = item.itemIdentifier, let originalName = assetNameProvider(identifier) else {
            let fileExtension = item.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
            return "\(UUIDEnvironment.uuid().uuidString).\(fileExtension)"
        }

        return originalName
    }
}

private extension PHAsset {
    static func name(for identifier: String) -> String? {
        fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            .firstObject
            .flatMap { asset in PHAssetResource.assetResources(for: asset).first?.originalFilename }
    }
}

extension PhotosPickerItem: PhotosItem {}
extension PhotosPickerItem: PhotosItemLoading {
    func loadTransferableData() async throws -> Data? {
        try await loadTransferable(type: Data.self)
    }
}
