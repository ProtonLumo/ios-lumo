import PhotosUI
import Testing
import UniformTypeIdentifiers

@testable import LumoComposer

struct PhotoFileNameExtractorTests {
    @Test
    func fileName_WhenAssetNameAvailable_ReturnsAssetName() {
        let name = PhotoFileNameExtractor.fileName(
            from: TestPhotosItem(itemIdentifier: "some-identifier", supportedContentTypes: [.jpeg]),
            assetNameProvider: { _ in "IMG_1234.HEIC" }
        )

        #expect(name == "IMG_1234.HEIC")
    }

    @Test(.stubbedUUID(.init(uuidString: "00000000-0000-0000-0000-000000000001")!))
    func fileName_WhenIdentifierIsNil_ReturnsUUIDWithInferredExtension() {
        let name = PhotoFileNameExtractor.fileName(
            from: TestPhotosItem(itemIdentifier: .none, supportedContentTypes: [.heic]),
            assetNameProvider: { _ in nil }
        )

        #expect(name == "00000000-0000-0000-0000-000000000001.heic")
    }

    @Test(.stubbedUUID(.init(uuidString: "00000000-0000-0000-0000-000000000002")!))
    func fileName_WhenAssetNameProviderReturnsNil_ReturnsUUIDWithInferredExtension() {
        let name = PhotoFileNameExtractor.fileName(
            from: TestPhotosItem(itemIdentifier: "some-identifier", supportedContentTypes: [.png]),
            assetNameProvider: { _ in nil }
        )

        #expect(name == "00000000-0000-0000-0000-000000000002.png")
    }

    @Test(.stubbedUUID(.init(uuidString: "00000000-0000-0000-0000-000000000003")!))
    func fileName_WhenContentTypesEmpty_FallsBackToJpgExtension() {
        let name = PhotoFileNameExtractor.fileName(
            from: TestPhotosItem(itemIdentifier: .none, supportedContentTypes: []),
            assetNameProvider: { _ in nil }
        )

        #expect(name == "00000000-0000-0000-0000-000000000003.jpg")
    }
}

private struct TestPhotosItem: PhotosItem {
    var itemIdentifier: String?
    var supportedContentTypes: [UTType]
}
