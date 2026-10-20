import CoreText
import Foundation

enum FontRegistrar {
    private static let fileNames = ["Inter-Regular", "Inter-Medium", "Inter-SemiBold", "Inter-Bold"]

    /// Registers the bundled Inter faces for the lifetime of the process.
    static func registerFonts() {
        for name in fileNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
