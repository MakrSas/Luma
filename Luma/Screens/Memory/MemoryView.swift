import SwiftUI

struct MemoryView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: NavigationPath
    @State private var selectedCategory: MemoryCategory?

    private var filtered: [MemoryRecord] {
        guard let selectedCategory else { return appState.memoryRecords }
        return appState.memoryRecords.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VStack(spacing: 0) {
            modePicker
            categoryFilter
            List {
                ForEach(filtered.sorted(by: { $0.isPinned && !$1.isPinned })) { record in
                    Button {
                        path.append(Route.memoryEditor(record.id))
                    } label: {
                        MemoryRow(record: record)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    let ids = offsets.map { filtered.sorted(by: { $0.isPinned && !$1.isPinned })[$0].id }
                    appState.memoryRecords.removeAll { ids.contains($0.id) }
                }
            }
            .listStyle(.plain)
        }
        .background(LumaColor.canvas.ignoresSafeArea())
        .navigationTitle("Память")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    path.append(Route.memoryEditor(nil))
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private var modePicker: some View {
        @Bindable var appState = appState
        return Picker("Режим памяти", selection: $appState.memoryMode) {
            ForEach(MemoryMode.allCases) { mode in
                Text(mode.label).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, LumaSpacing.md)
        .padding(.top, LumaSpacing.sm)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LumaSpacing.xs) {
                filterChip(nil, label: "Все")
                ForEach(MemoryCategory.allCases) { category in
                    filterChip(category, label: category.label)
                }
            }
            .padding(.horizontal, LumaSpacing.md)
        }
        .padding(.vertical, LumaSpacing.sm)
    }

    private func filterChip(_ category: MemoryCategory?, label: String) -> some View {
        let isSelected = selectedCategory == category
        return Button {
            selectedCategory = category
        } label: {
            Text(label)
                .font(LumaType.caption.weight(.medium))
                .foregroundStyle(isSelected ? LumaColor.onAccent : LumaColor.textPrimary)
                .padding(.horizontal, LumaSpacing.sm)
                .padding(.vertical, LumaSpacing.xxs)
                .background(isSelected ? LumaColor.accent : LumaColor.canvasElevated, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MemoryView(path: .constant(NavigationPath()))
    }
    .environment(AppState())
}

private struct MemoryRow: View {
    var record: MemoryRecord

    var body: some View {
        HStack(alignment: .top, spacing: LumaSpacing.sm) {
            Image(systemName: record.category.systemImage)
                .foregroundStyle(LumaColor.accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: LumaSpacing.xxs) {
                    Text(record.title)
                        .font(LumaType.subheadline.weight(.semibold))
                        .foregroundStyle(LumaColor.textPrimary)
                    if record.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(LumaColor.textTertiary)
                    }
                    if record.isSensitive {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(LumaColor.warning)
                    }
                }
                Text(record.content)
                    .font(LumaType.footnote)
                    .foregroundStyle(LumaColor.textSecondary)
                    .lineLimit(2)
                Text("\(record.scope.label) · \(record.category.label)")
                    .font(.system(size: 10))
                    .foregroundStyle(LumaColor.textTertiary)
            }
        }
        .padding(.vertical, LumaSpacing.xxs)
    }
}
