import Foundation

protocol VideoTemplatesRepository: Sendable {
    func fetchTemplates() async throws -> [VideoTemplate]
}
