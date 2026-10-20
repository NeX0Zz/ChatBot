import UIKit

enum PhotoSlotState {
    case empty
    case preparing
    case ready(UIImage)

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }
}
