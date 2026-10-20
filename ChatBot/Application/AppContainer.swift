import Foundation

/// Composition root: builds every dependency once and hands them to features through initializers.
@MainActor
final class AppContainer {
    let router = AppRouter()
    let toastCenter = ToastCenter()
    let subscriptionManager: SubscriptionManager
    let chatStore: ChatStore
    let videoCoordinator: VideoGenerationCoordinator
    let photoLibrary = PhotoLibraryService()
    let tracking = TrackingAuthorizationService()
    let videoFileCache = VideoFileCache()
    let thumbnailCache = VideoThumbnailCache()
    let cacheCleaner: MediaCacheCleaner
    let premiumGate: PremiumGate

    let templatesStore: VideoTemplatesStore
    let chatCompletionRepository: ChatCompletionRepository

    init() {
        let subscriptionRepository = ApphudSubscriptionRepository(
            apiKey: AppConfig.Apphud.apiKey,
            paywallIdentifier: AppConfig.Apphud.paywallIdentifier
        )
        subscriptionManager = SubscriptionManager(repository: subscriptionRepository)

        // Apphud generates the user id synchronously on start; the API needs it on every call.
        let userIdBox = UserIdBox()
        let clientConfiguration = URLSessionAPIClient.Configuration(
            bearerToken: AppConfig.API.bearerToken,
            applicationId: AppConfig.API.applicationId,
            timeout: AppConfig.API.requestTimeout,
            uploadTimeout: AppConfig.API.uploadTimeout
        )
        let apiClient = URLSessionAPIClient(configuration: clientConfiguration) { userIdBox.value }

        chatCompletionRepository = RemoteChatCompletionRepository(client: apiClient, baseURL: AppConfig.API.chatBaseURL)
        templatesStore = VideoTemplatesStore(
            repository: RemoteVideoTemplatesRepository(
                client: apiClient,
                baseURL: AppConfig.API.videoBaseURL,
                applicationId: AppConfig.API.applicationId
            )
        )
        chatStore = ChatStore(repository: LocalChatHistoryRepository())
        videoCoordinator = VideoGenerationCoordinator(
            generationRepository: RemoteVideoGenerationRepository(client: apiClient, baseURL: AppConfig.API.videoBaseURL),
            historyRepository: LocalVideoHistoryRepository()
        )

        premiumGate = PremiumGate(subscriptionManager: subscriptionManager, router: router)
        cacheCleaner = MediaCacheCleaner(videoFileCache: videoFileCache, thumbnailCache: thumbnailCache)

        subscriptionManager.start()
        userIdBox.value = subscriptionManager.userId
    }

    /// Asks for tracking consent once and hands the resulting identifiers to Apphud for attribution.
    func requestTrackingAuthorization() async {
        let advertisingId = await tracking.requestAuthorizationIfNeeded()
        subscriptionManager.updateAdvertisingIdentifier(advertisingId)
    }
}
