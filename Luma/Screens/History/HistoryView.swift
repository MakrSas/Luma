import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: NavigationPath
    @State private var query: String = ""
    @State private var renamingID: UUID?
    @State private var renameText: String = ""

    private var filtered: [Conversation] {
        let all = appState.conversations
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        return all.filter {
            $0.title.localizedCaseInsensitiveContains(query) || $0.summary.localizedCaseInsensitiveContains(query)
        }
    }

    private var pinned: [Conversation] { filtered.filter(\.isPinned) }
    private var rest: [Conversation] { filtered.filter { !$0.isPinned } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumaSpacing.lg) {
                header

                if !pinned.isEmpty {
                    sectionLabel("Закреплённые")
                    MasonryLayout(spacing: LumaSpacing.sm) {
                        ForEach(pinned) { conversation in
                            card(for: conversation)
                        }
                    }
                }

                if !rest.isEmpty {
                    sectionLabel("Все диалоги")
                    MasonryLayout(spacing: LumaSpacing.sm) {
                        ForEach(rest) { conversation in
                            card(for: conversation)
                        }
                    }
                }

                if filtered.isEmpty {
                    Text("Ничего не найдено")
                        .font(LumaType.subheadline)
                        .foregroundStyle(LumaColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, LumaSpacing.xl)
                }
            }
            .padding(.horizontal, LumaSpacing.md)
            .padding(.bottom, LumaSpacing.xl)
        }
        .background(LumaColor.canvas.ignoresSafeArea())
        .navigationTitle("История")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Поиск диалогов")
        .alert("Переименовать диалог", isPresented: Binding(get: { renamingID != nil }, set: { if !$0 { renamingID = nil } })) {
            TextField("Название", text: $renameText)
            Button("Отмена", role: .cancel) { renamingID = nil }
            Button("Сохранить") {
                if let id = renamingID, let idx = appState.conversations.firstIndex(where: { $0.id == id }) {
                    appState.conversations[idx].title = renameText
                }
                renamingID = nil
            }
        }
    }

    private var header: some View {
        Text("История")
            .font(LumaType.display())
            .foregroundStyle(LumaColor.textPrimary)
            .padding(.top, LumaSpacing.xs)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(LumaType.caption.weight(.semibold))
            .foregroundStyle(LumaColor.textTertiary)
            .textCase(.uppercase)
    }

    private func card(for conversation: Conversation) -> some View {
        Button {
            appState.activeConversationID = conversation.id
            path.append(Route.conversation(conversation.id))
        } label: {
            HistoryCard(conversation: conversation)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                if let idx = appState.conversations.firstIndex(where: { $0.id == conversation.id }) {
                    appState.conversations[idx].isPinned.toggle()
                }
            } label: {
                Label(conversation.isPinned ? "Открепить" : "Закрепить", systemImage: conversation.isPinned ? "pin.slash" : "pin")
            }
            Button {
                renameText = conversation.title
                renamingID = conversation.id
            } label: {
                Label("Переименовать", systemImage: "pencil")
            }
            Button(role: .destructive) {
                appState.conversations.removeAll { $0.id == conversation.id }
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView(path: .constant(NavigationPath()))
    }
    .environment(AppState())
}

private struct HistoryCard: View {
    var conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: LumaSpacing.xs) {
            if let icon = conversation.heroImageName {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: LumaRadius.medium, style: .continuous)
                        .fill(LumaColor.accent.opacity(0.16))
                        .frame(height: heroHeight)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 30))
                                .foregroundStyle(LumaColor.accent)
                        )
                    if conversation.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(.black.opacity(0.35), in: Circle())
                            .padding(6)
                    }
                }
            }

            if let tag = conversation.accentTag {
                Text(tag.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(LumaColor.accent)
                    .padding(.top, conversation.heroImageName == nil ? LumaSpacing.xs : 0)
            }

            Text(conversation.title)
                .font(LumaType.headline)
                .foregroundStyle(LumaColor.textPrimary)
                .lineLimit(2)

            if !conversation.summary.isEmpty {
                Text(conversation.summary)
                    .font(LumaType.footnote)
                    .foregroundStyle(LumaColor.textSecondary)
                    .lineLimit(3)
            }

            Text(conversation.updatedAt, format: .relative(presentation: .named))
                .font(LumaType.caption)
                .foregroundStyle(LumaColor.textTertiary)
        }
        .padding(LumaSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LumaColor.canvasElevated, in: RoundedRectangle(cornerRadius: LumaRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LumaRadius.medium, style: .continuous)
                .strokeBorder(LumaColor.separator.opacity(0.6), lineWidth: 0.5)
        )
    }

    private var heroHeight: CGFloat {
        conversation.isPinned ? 96 : 72
    }
}
