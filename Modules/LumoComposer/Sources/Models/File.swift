struct File: Equatable, Decodable {
    let id: String
    let name: String
    let type: FileType
    /// Base64-encoded thumbnail for display purposes.
    ///
    /// The WebAPI only returns this value on the initial file upload.
    /// Subsequent state updates always deliver it as `nil`, even for already-attached files.
    /// Native code caches this value in `ComposerViewState` for the duration of the session.
    let preview: String?
}
