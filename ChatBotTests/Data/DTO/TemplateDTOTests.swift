import Foundation
import Testing
@testable import ChatBot

@Suite("TemplateDTO")
struct TemplateDTOTests {
    @Test("Decodes a full template with snake_case keys")
    func full() throws {
        let json = """
        {"id": 1, "template_id": 11, "name": "Dance", "category": "Fun", "prompt": "p", "duration": 7,
         "qualities": ["720p"], "preview_small": "s", "preview_large": "l", "is_active": false}
        """

        let dto = try JSONDecoder().decode(TemplateDTO.self, from: Data(json.utf8))

        #expect(dto.id == 1 && dto.templateId == 11 && dto.name == "Dance")
        #expect(dto.category == "Fun" && dto.prompt == "p" && dto.duration == 7)
        #expect(dto.qualities == ["720p"] && dto.previewSmall == "s" && dto.previewLarge == "l")
        #expect(dto.isActive == false)
    }

    @Test("Optional fields may be absent")
    func minimal() throws {
        let json = #"{"id": 1, "template_id": 2, "name": "N"}"#

        let dto = try JSONDecoder().decode(TemplateDTO.self, from: Data(json.utf8))

        #expect(dto.category == nil && dto.prompt == nil && dto.duration == nil)
        #expect(dto.qualities == nil && dto.previewSmall == nil && dto.previewLarge == nil && dto.isActive == nil)
    }

    @Test("Missing required fields throw", arguments: [
        #"{"template_id": 2, "name": "N"}"#,
        #"{"id": 1, "name": "N"}"#,
        #"{"id": 1, "template_id": 2}"#
    ])
    func missingRequired(json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(TemplateDTO.self, from: Data(json.utf8))
        }
    }
}
