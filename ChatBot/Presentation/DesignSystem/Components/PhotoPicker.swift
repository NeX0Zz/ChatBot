import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// Single-image picker. Present it in a sheet bound to `isPresented`.
struct PhotoPicker: UIViewControllerRepresentable {
    enum PickerError: Error {
        case noImageData
    }

    @Binding var isPresented: Bool
    let onPick: (Result<Data, Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, onPick: onPick)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let isPresented: Binding<Bool>
        private let onPick: (Result<Data, Error>) -> Void

        init(isPresented: Binding<Bool>, onPick: @escaping (Result<Data, Error>) -> Void) {
            self.isPresented = isPresented
            self.onPick = onPick
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            isPresented.wrappedValue = false
            guard let provider = results.first?.itemProvider else { return }

            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [onPick] data, error in
                let result: Result<Data, Error>
                if let data {
                    result = .success(data)
                } else {
                    result = .failure(error ?? PickerError.noImageData)
                }
                DispatchQueue.main.async { onPick(result) }
            }
        }
    }
}
