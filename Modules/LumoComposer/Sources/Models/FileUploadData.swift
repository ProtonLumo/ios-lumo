/// Data for a file to be uploaded from native to web
public struct FileUploadData: Equatable, Encodable {
    let base64: String
    let name: String
}
