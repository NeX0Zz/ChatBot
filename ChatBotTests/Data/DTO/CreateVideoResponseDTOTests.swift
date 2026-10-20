import Foundation
import Testing
@testable import ChatBot

@Suite("CreateVideoResponseDTO")
struct CreateVideoResponseDTOTests {
    private func decode(_ json: String) throws -> CreateVideoResponseDTO {
        try JSONDecoder().decode(CreateVideoResponseDTO.self, from: Data(json.utf8))
    }

    @Test("Decodes a numeric id")
    func intId() throws {
        #expect(try decode(#"{"video_id": 12345}"#).videoId == "12345")
    }

    @Test("Decodes a string id")
    func stringId() throws {
        #expect(try decode(#"{"video_id": "abc-1"}"#).videoId == "abc-1")
    }

    @Test("A numeric string stays a string")
    func numericString() throws {
        #expect(try decode(#"{"video_id": "007"}"#).videoId == "007")
    }

    @Test("Missing id throws")
    func missingId() {
        #expect(throws: DecodingError.self) { try decode(#"{"other": 1}"#) }
    }

    @Test("Null or boolean id throws", arguments: [#"{"video_id": null}"#, #"{"video_id": true}"#])
    func invalidId(json: String) {
        #expect(throws: DecodingError.self) { try decode(json) }
    }
}
