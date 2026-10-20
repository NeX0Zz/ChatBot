import SwiftUI

extension View {
    /// System alert with a single OK button, shown while `message` is non-nil.
    func alertMessage(_ message: Binding<AlertMessage?>) -> some View {
        alert(
            message.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { if !$0 { message.wrappedValue = nil } }
            ),
            presenting: message.wrappedValue
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { alert in
            Text(alert.message)
        }
    }
}
