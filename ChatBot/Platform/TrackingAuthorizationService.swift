import AdSupport
import AppTrackingTransparency

/// App Tracking Transparency prompt. Returns the IDFA only when the user allowed tracking.
@MainActor
final class TrackingAuthorizationService {
    /// Shows the system prompt once; later calls return the stored decision without UI.
    /// The system ignores the request unless the app is active, so call it after the first screen is up.
    func requestAuthorizationIfNeeded() async -> String? {
        let status: ATTrackingManager.AuthorizationStatus
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            status = await ATTrackingManager.requestTrackingAuthorization()
        } else {
            status = ATTrackingManager.trackingAuthorizationStatus
        }
        guard status == .authorized else { return nil }
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
}
