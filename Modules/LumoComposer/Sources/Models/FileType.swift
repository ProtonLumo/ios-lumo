import LumoDesignSystem
import SwiftUI

enum FileType: String, Equatable {
    case album = "Album"
    case attachments = "Attachments"
    case calendar = "Calendar"
    case doc = "Doc"
    case folder = "Folder"
    case font = "Font"
    case image = "Image"
    case keynote = "Keynote"
    case keytrust = "Keytrust"
    case numbers = "Numbers"
    case pages = "Pages"
    case pdf = "PDF"
    case ppt = "PPT"
    case protonDoc = "ProtonDoc"
    case protonSheet = "ProtonSheet"
    case sound = "Sound"
    case text = "Text"
    case unknown = "Unknown"
    case video = "Video"
    case xls = "XLS"
    case xml = "XML"
    case zip = "Zip"

    var image: Image {
        switch self {
        case .album:
            DS.Icon.mimeMdAlbum.swiftUIImage
        case .attachments:
            DS.Icon.mimeMdAttachments.swiftUIImage
        case .calendar:
            DS.Icon.mimeMdCalendar.swiftUIImage
        case .doc:
            DS.Icon.mimeMdDoc.swiftUIImage
        case .folder:
            DS.Icon.mimeMdFolder.swiftUIImage
        case .font:
            DS.Icon.mimeMdFont.swiftUIImage
        case .image:
            DS.Icon.mimeMdImage.swiftUIImage
        case .keynote:
            DS.Icon.mimeMdKeynote.swiftUIImage
        case .keytrust:
            DS.Icon.mimeMdKeytrust.swiftUIImage
        case .numbers:
            DS.Icon.mimeMdNumbers.swiftUIImage
        case .pages:
            DS.Icon.mimeMdPages.swiftUIImage
        case .pdf:
            DS.Icon.mimeMdPdf.swiftUIImage
        case .ppt:
            DS.Icon.mimeMdPpt.swiftUIImage
        case .protonDoc:
            DS.Icon.mimeMdProtonDoc.swiftUIImage
        case .protonSheet:
            DS.Icon.mimeMdProtonSheet.swiftUIImage
        case .sound:
            DS.Icon.mimeMdSound.swiftUIImage
        case .text:
            DS.Icon.mimeMdText.swiftUIImage
        case .unknown:
            DS.Icon.mimeMdUnknown.swiftUIImage
        case .video:
            DS.Icon.mimeMdVideo.swiftUIImage
        case .xls:
            DS.Icon.mimeMdXls.swiftUIImage
        case .xml:
            DS.Icon.mimeMdXml.swiftUIImage
        case .zip:
            DS.Icon.mimeMdZip.swiftUIImage
        }
    }
}
