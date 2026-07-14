import SwiftUI
import UIKit

@main
struct IconPreviewApp: App {
    var body: some Scene {
        WindowGroup {
            IconPickerView()
        }
    }
}

private struct IconOption: Identifiable {
    let id: String
    let displayName: String
    /// nil means the primary icon (UIApplication.setAlternateIconName(nil))
    let alternateName: String?
}

private let iconOptions: [IconOption] = [
    IconOption(id: "default", displayName: "Luma", alternateName: nil),
    IconOption(id: "metal", displayName: "Luma Металл", alternateName: "AppIcon-Metal"),
    IconOption(id: "metalDither", displayName: "Luma Металл Дизер", alternateName: "AppIcon-MetalDither"),
    IconOption(id: "dither", displayName: "Luma Дизер", alternateName: "AppIcon-Dither"),
    IconOption(id: "ditherGreen", displayName: "Luma Дизер Зелёный", alternateName: "AppIcon-DitherGreen"),
]

private struct IconPickerView: View {
    @State private var currentAlternateName: String? = UIApplication.shared.alternateIconName
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List(iconOptions) { option in
                Button {
                    select(option)
                } label: {
                    HStack {
                        Text(option.displayName)
                        Spacer()
                        if currentAlternateName == option.alternateName {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Выбор иконки")
            .alert("Не удалось сменить иконку", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func select(_ option: IconOption) {
        guard UIApplication.shared.supportsAlternateIcons else {
            errorMessage = "Это устройство не поддерживает смену иконок."
            return
        }
        UIApplication.shared.setAlternateIconName(option.alternateName) { error in
            DispatchQueue.main.async {
                if let error {
                    errorMessage = error.localizedDescription
                } else {
                    currentAlternateName = option.alternateName
                }
            }
        }
    }
}
