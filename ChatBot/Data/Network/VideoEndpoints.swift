import Foundation

enum VideoEndpoints {
    static func templates(applicationId: String, baseURL: URL) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "api/v1/get_templates/\(applicationId)", includesUserContext: false)
    }

    static func templateToVideo(templateId: Int, imageData: Data, quality: VideoQuality, baseURL: URL) -> Endpoint {
        var form = MultipartFormData()
        form.append(String(templateId), name: "template_id")
        form.append(quality.rawValue, name: "quality")
        form.append(imageData, name: "image", fileName: "photo.jpg", mimeType: "image/jpeg")
        return Endpoint(baseURL: baseURL, path: "api/v1/template2video", method: .post, body: .multipart(form))
    }

    static func status(jobId: String, baseURL: URL) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "api/v1/status", queryItems: [URLQueryItem(name: "id", value: jobId)])
    }
}
