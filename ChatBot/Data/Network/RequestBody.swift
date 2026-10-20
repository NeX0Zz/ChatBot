import Foundation

enum RequestBody: Sendable {
    case none
    case json(Data)
    case multipart(MultipartFormData)

    static func json<T: Encodable>(_ value: T, encoder: JSONEncoder = JSONEncoder()) throws -> RequestBody {
        .json(try encoder.encode(value))
    }
}
