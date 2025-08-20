import Foundation

enum BundleError: Error {
    case fileNotFound(String)
    case dataLoadingFailed(String)
    case decodingFailed(String)
    case jsonSerializationFailed(String)
}

extension Bundle {

    func decode<T: Decodable>(_ type: T.Type, from file: String) throws -> T {

        guard let url = Bundle.main.url(forResource: file, withExtension: nil) else {
            throw BundleError.fileNotFound("Failed to locate \(file) in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            throw BundleError.dataLoadingFailed("Failed to load \(file) from bundle.")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .lowerCamelCase

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw BundleError.decodingFailed("Failed to decode \(file) from bundle: \(error.localizedDescription)")
        }
    }

    func loadJsonDataToDic(from file: String) throws -> [String: Any] {

        guard let url = Bundle.main.url(forResource: file, withExtension: nil) else {
            throw BundleError.fileNotFound("Failed to locate \(file) in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            throw BundleError.dataLoadingFailed("Failed to load \(file) from bundle.")
        }

        do {
            guard let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw BundleError.jsonSerializationFailed("Failed to cast JSON data to [String: Any] from \(file).")
            }
            return jsonData
        } catch {
            throw BundleError.jsonSerializationFailed("Failed to generate json data from \(file): \(error.localizedDescription)")
        }
    }

    func loadJsonData(from file: String) throws -> Any {

        guard let url = Bundle.main.url(forResource: file, withExtension: nil) else {
            throw BundleError.fileNotFound("Failed to locate \(file) in bundle.")
        }

        guard let data = try? Data(contentsOf: url) else {
            throw BundleError.dataLoadingFailed("Failed to load \(file) from bundle.")
        }

        do {
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            throw BundleError.jsonSerializationFailed("Failed to generate json data from \(file): \(error.localizedDescription)")
        }
    }
}
