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

    /// iOS app icons use a "squircle" — a continuous corner radius of
    /// roughly 22.37% of the icon's side length, not an arbitrary card
    /// radius — so previews here read as real Home Screen icons.
    private static let iconCornerRatio: CGFloat = 0.2237
    private static let cellSize: CGFloat = 64

    private let columns = [
        GridItem(.adaptive(minimum: cellSize, maximum: cellSize), spacing: LumaSpacing.lg)
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
        .alert(
            "Не удалось сменить значок",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("ОК", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func iconCell(_ option: AppIconOption) -> some View {
        let isSelected = option.name == currentIconName
        let cornerRadius = Self.cellSize * Self.iconCornerRatio
        return Button {
            select(option)
        } label: {
            VStack(spacing: LumaSpacing.xs) {
                Image(option.previewAsset)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: Self.cellSize, height: Self.cellSize)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .inset(by: -3)
                            .strokeBorder(LumaColor.accent, lineWidth: 2)
                            .opacity(isSelected ? 1 : 0)
                    )

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
