import Foundation
import Testing
@testable import ChatBot

@Suite("MultipartFormData")
struct MultipartFormDataTests {
    @Test("Empty form is just the closing boundary")
    func emptyForm() {
        let form = MultipartFormData()

        #expect(String(decoding: form.encoded(), as: UTF8.self) == "--\(form.boundary)--\r\n")
    }

    @Test("Text part has a disposition and no content type")
    func textPart() {
        var form = MultipartFormData()
        form.append("42", name: "template_id")

        let expected = "--\(form.boundary)\r\n"
            + "Content-Disposition: form-data; name=\"template_id\"\r\n"
            + "\r\n"
            + "42\r\n"
            + "--\(form.boundary)--\r\n"
        #expect(String(decoding: form.encoded(), as: UTF8.self) == expected)
    }

    @Test("File part carries filename and content type")
    func filePart() {
        var form = MultipartFormData()
        form.append(Data("DATA".utf8), name: "image", fileName: "photo.jpg", mimeType: "image/jpeg")

        let expected = "--\(form.boundary)\r\n"
            + "Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n"
            + "Content-Type: image/jpeg\r\n"
            + "\r\n"
            + "DATA\r\n"
            + "--\(form.boundary)--\r\n"
        #expect(String(decoding: form.encoded(), as: UTF8.self) == expected)
    }

    @Test("Parts keep insertion order and each has its own boundary line")
    func partsOrder() {
        var form = MultipartFormData()
        form.append("1", name: "a")
        form.append("2", name: "b")
        form.append(Data("3".utf8), name: "c", fileName: "c.bin", mimeType: "application/octet-stream")

        let text = String(decoding: form.encoded(), as: UTF8.self)
        let separator = "--\(form.boundary)\r\n"
        #expect(text.components(separatedBy: separator).count - 1 == 3)
        #expect(text.hasSuffix("--\(form.boundary)--\r\n"))
        let positions = ["name=\"a\"", "name=\"b\"", "name=\"c\""].compactMap { text.range(of: $0)?.lowerBound }
        #expect(positions.count == 3)
        #expect(positions == positions.sorted())
    }

    @Test("Binary payload is written byte for byte")
    func binaryPayload() throws {
        let payload = Data([0x00, 0xFF, 0xD8, 0xFF, 0xE0, 0x0D, 0x0A, 0x80])
        var form = MultipartFormData()
        form.append(payload, name: "image", fileName: "photo.jpg", mimeType: "image/jpeg")

        let encoded = form.encoded()

        #expect(encoded.range(of: payload) != nil)
    }

    @Test("Content type announces the boundary")
    func contentType() {
        let form = MultipartFormData()

        #expect(form.contentType == "multipart/form-data; boundary=\(form.boundary)")
        #expect(form.boundary.hasPrefix("Boundary-"))
    }

    @Test("Every form gets a unique boundary")
    func uniqueBoundary() {
        #expect(MultipartFormData().boundary != MultipartFormData().boundary)
    }
}
