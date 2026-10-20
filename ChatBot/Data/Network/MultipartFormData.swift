import Foundation

struct MultipartFormData: Sendable {
    private struct Part: Sendable {
        let name: String
        let fileName: String?
        let mimeType: String?
        let data: Data
    }

    let boundary = "Boundary-\(UUID().uuidString)"
    private var parts: [Part] = []

    var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    mutating func append(_ value: String, name: String) {
        parts.append(Part(name: name, fileName: nil, mimeType: nil, data: Data(value.utf8)))
    }

    mutating func append(_ data: Data, name: String, fileName: String, mimeType: String) {
        parts.append(Part(name: name, fileName: fileName, mimeType: mimeType, data: data))
    }

    func encoded() -> Data {
        var body = Data()
        for part in parts {
            body.append("--\(boundary)\r\n")
            var disposition = "Content-Disposition: form-data; name=\"\(part.name)\""
            if let fileName = part.fileName {
                disposition += "; filename=\"\(fileName)\""
            }
            body.append(disposition + "\r\n")
            if let mimeType = part.mimeType {
                body.append("Content-Type: \(mimeType)\r\n")
            }
            body.append("\r\n")
            body.append(part.data)
            body.append("\r\n")
        }
        body.append("--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
