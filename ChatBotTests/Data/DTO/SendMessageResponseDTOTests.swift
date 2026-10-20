import Foundation
import Testing
@testable import ChatBot

@Suite("SendMessageResponseDTO and SendMessageRequestDTO")
struct SendMessageResponseDTOTests {
    @Test("Decodes snake_case keys")
    func decodesSnakeCase() throws {
        let json = #"{"chat_id": "c-1", "assistant_message": "Hi there"}"#

        let dto = try JSONDecoder().decode(SendMessageResponseDTO.self, from: Data(json.utf8))

        #expect(dto.chatId == "c-1")
        #expect(dto.assistantMessage == "Hi there")
    }

    @Test("Camel case keys are not accepted")
    func rejectsCamelCase() {
        let json = #"{"chatId": "c-1", "assistantMessage": "Hi"}"#

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(SendMessageResponseDTO.self, from: Data(json.utf8))
        }
    }

    @Test("Missing assistant message throws")
    func missingMessage() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(SendMessageResponseDTO.self, from: Data(#"{"chat_id": "c"}"#.utf8))
        }
    }

    @Test("Request encodes as {message}")
    func encodesRequest() throws {
        let data = try JSONEncoder().encode(SendMessageRequestDTO(message: "hey"))

        #expect(try JSONSerialization.jsonObject(with: data) as? [String: String] == ["message": "hey"])
    }
}
