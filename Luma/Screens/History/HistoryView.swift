import SwiftUI

/// Launch screen. Structure follows the reference screenshots exactly: a
/// masonry grid of cards with a small date/pin meta line, no page title, a
/// floating filter/options button top-trailing, and floating search +
/// compose buttons bottom-leading/trailing. No standard navigation bar.
struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: NavigationPath

    @State private var query: String = ""
    @State private var isSearching = false
    @State private var sortNewestFirst = true
    @State private var renamingID: UUID?
    @State private var renameText: String = ""
    @FocusState private var searchFocused: Bool

    private var filtered: [Conversation] {
        var all = appState.conversations
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            all = all.filter {
                $0.title.localizedCaseInsensitiveContains(trimmed) || $0.summary.localizedCaseInsensitiveContains(trimmed)
            }
        }
        all.sort { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            return sortNewestFirst ? a.updatedAt > b.updatedAt : a.updatedAt < b.updatedAt
        }
        return all
    }

    var body: some View {
        ScrollView {
            MasonryLayout(spacing: LumaSpacing.sm) {
                ForEach(filtered) { conversation in
                    card(for: conversation)
                }
            }
            .padding(.horizontal, LumaSpacing.md)
            .padding(.top, LumaSpacing.sm)

            if filtered.isEmpty {
                Text("Ничего не найдено")
                    .font(LumaType.subheadline)
                    .foregroundStyle(LumaColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, LumaSpacing.xl)
            }
        }
        .background(LumaColor.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                optionsButton
            }
            .padding(.horizontal, LumaSpacing.md)
            .padding(.top, LumaSpacing.xs)
            .padding(.bottom, LumaSpacing.xs)
        }
        .safeAreaInset(edge: .bottom) {
            bottomControls
                .padding(.horizontal, LumaSpacing.md)
                .padding(.bottom, LumaSpacing.sm)
        }
        .toolbar(.hidden, for: .navigationBar)
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

    private var optionsButton: some View {
        Menu {
            Section("Сортировка") {
                Button {
                    sortNewestFirst = true
                } label: {
                    if sortNewestFirst {
                        Label("Сначала новые", systemImage: "checkmark")
                    } else {
                        Text("Сначала новые")
                    }
                }
                Button {
                    sortNewestFirst = false
                } label: {
                    if !sortNewestFirst {
                        Label("Сначала старые", systemImage: "checkmark")
                    } else {
                        Text("Сначала старые")
                    }
                }
            }
            Button {
                path.append(Route.settingsHub)
            } label: {
                Label("Настройки", systemImage: "gearshape")
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
        }
        .buttonBorderShape(.circle)
        .lumaGlassButtonStyle()
        .frame(width: 44, height: 44)
    }

    /// Per Apple's iOS 26 Liquid Glass guidance, search lives permanently in
    /// the bottom bar. Collapsed it's a plain circular icon button (matching
    /// `composeButton`'s size/shape); tapping it expands it in place to a
    /// full-width field — the compose button steps aside rather than search
    /// appearing somewhere else on screen.
    private var bottomControls: some View {
        HStack(spacing: LumaSpacing.xs) {
            searchControl
            if !isSearching {
                Spacer(minLength: 0)
                composeButton
            }
        }
    }

    @ViewBuilder
    private var searchControl: some View {
        if isSearching {
            HStack(spacing: LumaSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(LumaColor.textSecondary)
                TextField("Поиск диалогов", text: $query)
                    .font(LumaType.body)
                    .focused($searchFocused)
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isSearching = false
                        query = ""
                        searchFocused = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(LumaColor.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, LumaSpacing.md)
            .padding(.vertical, LumaSpacing.sm)
            .frame(maxWidth: .infinity)
            .glassSurface(cornerRadius: LumaRadius.pill)
        } else {
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    isSearching = true
                    searchFocused = true
                }
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .buttonBorderShape(.circle)
            .lumaGlassButtonStyle()
            .frame(width: 44, height: 44)
        }
    }

    private var composeButton: some View {
        Button {
            let id = appState.startNewConversation()
            path.append(Route.conversation(id))
        } label: {
            Image(systemName: "square.and.pencil")
                .foregroundStyle(LumaColor.onAccent)
        }
        .buttonBorderShape(.circle)
        .lumaGlassProminentButtonStyle()
        .frame(width: 44, height: 44)
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

/// Formats a card's meta line the way the reference does: clock time for
/// today, "Вчера" for yesterday, weekday name within the last week,
/// otherwise a short date.
private func metaLabel(for date: Date) -> String {
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
        return date.formatted(date: .omitted, time: .shortened)
    }
    if calendar.isDateInYesterday(date) {
        return "Вчера"
    }
    if let days = calendar.dateComponents([.day], from: date, to: .now).day, days < 7 {
        return date.formatted(.dateTime.weekday(.wide))
    }
    return date.formatted(date: .numeric, time: .omitted)
}

private struct HistoryCard: View {
    var conversation: Conversation

    var body: some View {
        textCard
            .background(LumaColor.canvasElevated, in: RoundedRectangle(cornerRadius: LumaRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LumaRadius.medium, style: .continuous)
                    .strokeBorder(LumaColor.separator.opacity(0.6), lineWidth: 0.5)
            )
    }

    private var metaRow: some View {
        HStack(spacing: LumaSpacing.xxs) {
            if conversation.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9))
            }
            Text(metaLabel(for: conversation.updatedAt))
        }
        .font(.system(size: 11, weight: .medium))
    }

    private var textCard: some View {
        VStack(alignment: .leading, spacing: LumaSpacing.xxs) {
            metaRow
                .foregroundStyle(LumaColor.textTertiary)

            Text(conversation.title)
                .font(LumaType.headline)
                .foregroundStyle(LumaColor.textPrimary)
                .lineLimit(2)
                .padding(.top, 2)

            if !conversation.summary.isEmpty {
                Text(conversation.summary)
                    .font(LumaType.footnote)
                    .foregroundStyle(LumaColor.textSecondary)
                    .lineLimit(4)
            }
        }
        .padding(LumaSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
