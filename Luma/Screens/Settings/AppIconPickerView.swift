import SwiftUI

private struct AppIconOption: Identifiable {
    let id: String
    let name: String?
    let previewAsset: String

    static let all: [AppIconOption] = [
        AppIconOption(id: "default", name: nil, previewAsset: "IconPreviewDefault"),
        AppIconOption(id: "metal", name: "AppIcon-Metal", previewAsset: "IconPreviewMetal"),
        AppIconOption(id: "metalDither", name: "AppIcon-MetalDither", previewAsset: "IconPreviewMetalDither"),
        AppIconOption(id: "dither", name: "AppIcon-Dither", previewAsset: "IconPreviewDither"),
        AppIconOption(id: "ditherGreen", name: "AppIcon-DitherGreen", previewAsset: "IconPreviewDitherGreen")
    ]

    var title: String {
        switch id {
        case "default": return "Обычная"
        case "metal": return "Металл"
        case "metalDither": return "Металл Дизер"
        case "dither": return "Дизер"
        case "ditherGreen": return "Дизер Зелёный"
        default: return id
        }
    }
}

struct AppIconPickerView: View {
    @State private var currentIconName: String? = UIApplication.shared.alternateIconName
    @State private var errorMessage: String?

    private let columns = [
        GridItem(.adaptive(minimum: 96, maximum: 120), spacing: LumaSpacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumaSpacing.lg) {
                Text("Выберите значок приложения на главном экране. Смена значка подтверждается системой iOS.")
                    .font(LumaType.subheadline)
                    .foregroundStyle(LumaColor.textSecondary)

                LazyVGrid(columns: columns, spacing: LumaSpacing.lg) {
                    ForEach(AppIconOption.all) { option in
                        iconCell(option)
                    }
                }
            }
            .padding(LumaSpacing.md)
        }
        .background(LumaColor.canvas.ignoresSafeArea())
        .navigationTitle("Значок приложения")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Не удалось сменить значок", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("ОК") { errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    private func iconCell(_ option: AppIconOption) -> some View {
        let isSelected = option.name == currentIconName
        return Button {
            select(option)
        } label: {
            VStack(spacing: LumaSpacing.xs) {
                Image(option.previewAsset)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: LumaRadius.medium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LumaRadius.medium, style: .continuous)
                            .strokeBorder(isSelected ? LumaColor.accent : LumaColor.separator, lineWidth: isSelected ? 2 : 0.5)
                    )
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(LumaColor.onAccent, LumaColor.accent)
                                .padding(6)
                        }
                    }

                Text(option.title)
                    .font(LumaType.footnote)
                    .foregroundStyle(LumaColor.textPrimary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private func select(_ option: AppIconOption) {
        guard option.name != currentIconName else { return }
        UIApplication.shared.setAlternateIconName(option.name) { error in
            if let error {
                errorMessage = error.localizedDescription
            } else {
                currentIconName = option.name
            }
        }
    }
}

#Preview {
    NavigationStack {
        AppIconPickerView()
    }
    .environment(AppState())
}
