import SwiftUI

struct MemoryEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    var recordID: UUID?

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var category: MemoryCategory = .fact
    @State private var scope: MemoryScope = .global
    @State private var isPinned: Bool = false
    @State private var isSensitive: Bool = false

    private var isNew: Bool { recordID == nil }

    var body: some View {
        Form {
            Section("Содержимое") {
                TextField("Заголовок", text: $title)
                TextField("Текст записи", text: $content, axis: .vertical)
                    .lineLimit(3...8)
            }
            Section("Категория и область") {
                Picker("Категория", selection: $category) {
                    ForEach(MemoryCategory.allCases) { c in
                        Label(c.label, systemImage: c.systemImage).tag(c)
                    }
                }
                Picker("Область", selection: $scope) {
                    ForEach(MemoryScope.allCases) { s in
                        Text(s.label).tag(s)
                    }
                }
            }
            Section("Параметры") {
                Toggle("Закрепить", isOn: $isPinned)
                Toggle("Чувствительные данные", isOn: $isSensitive)
            }
            if !isNew {
                Section {
                    Button("Удалить запись", role: .destructive) {
                        if let recordID {
                            appState.memoryRecords.removeAll { $0.id == recordID }
                        }
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(isNew ? "Новая запись" : "Редактирование")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Готово") {
                    save()
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear(perform: loadExisting)
    }

    private func loadExisting() {
        guard let recordID, let record = appState.memoryRecords.first(where: { $0.id == recordID }) else { return }
        title = record.title
        content = record.content
        category = record.category
        scope = record.scope
        isPinned = record.isPinned
        isSensitive = record.isSensitive
    }

    private func save() {
        if let recordID, let idx = appState.memoryRecords.firstIndex(where: { $0.id == recordID }) {
            appState.memoryRecords[idx].title = title
            appState.memoryRecords[idx].content = content
            appState.memoryRecords[idx].category = category
            appState.memoryRecords[idx].scope = scope
            appState.memoryRecords[idx].isPinned = isPinned
            appState.memoryRecords[idx].isSensitive = isSensitive
            appState.memoryRecords[idx].updatedAt = .now
        } else {
            let record = MemoryRecord(
                id: UUID(),
                category: category,
                scope: scope,
                title: title,
                content: content,
                isPinned: isPinned,
                isSensitive: isSensitive,
                createdAt: .now,
                updatedAt: .now
            )
            appState.memoryRecords.insert(record, at: 0)
        }
    }
}

#Preview {
    NavigationStack {
        MemoryEditorView(recordID: MemoryRecord.mockList[0].id)
    }
    .environment(AppState())
}
