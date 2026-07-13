import SwiftUI

enum AgentStatus: Equatable {
    case idle
    case thinking
    case runningTool(String)
    case awaitingConfirmation(String)
    case generating

    var label: String? {
        switch self {
        case .idle: return nil
        case .thinking: return "Думает…"
        case .runningTool(let name): return "Выполняет «\(name)»…"
        case .awaitingConfirmation(let name): return "Ожидает подтверждения: \(name)"
        case .generating: return "Печатает…"
        }
    }
}

struct ChatView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: NavigationPath
    var conversationID: UUID

    @State private var draft: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var status: AgentStatus = .idle
    @State private var isGenerating = false
    @State private var showModelPicker = false
    @State private var showIntelligencePicker = false
    @FocusState private var inputFocused: Bool

    private var conversation: Conversation? {
        appState.conversation(id: conversationID)
    }

    private var navTitle: String {
        if conversation?.isTemporary == true { return "Временный диалог" }
        return conversation?.title ?? "Luma"
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            messageScroll
            inputBar
        }
        .background(LumaColor.canvas.ignoresSafeArea())
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        let id = appState.startNewConversation(temporary: false)
                        path.append(Route.conversation(id))
                    } label: {
                        Label("Новый диалог", systemImage: "plus.bubble")
                    }
                    Button {
                        let id = appState.startNewConversation(temporary: true)
                        path.append(Route.conversation(id))
                    } label: {
                        Label("Временный диалог", systemImage: "timer")
                    }
                    Button {
                        path.append(Route.settingsHub)
                    } label: {
                        Label("Настройки", systemImage: "gearshape")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear(perform: loadMessages)
        .onChange(of: conversationID) { _, _ in loadMessages() }
        .sheet(isPresented: $showModelPicker) {
            ModelPickerSheet()
        }
        .sheet(isPresented: $showIntelligencePicker) {
            IntelligencePickerSheet()
        }
    }

    private var messageScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: LumaSpacing.md) {
                    if messages.isEmpty {
                        emptyState
                    }
                    ForEach(messages) { message in
                        messageRow(message)
                            .id(message.id)
                    }
                    if let label = status.label {
                        StatusIndicatorView(label: label)
                            .padding(.leading, LumaSpacing.xs)
                    }
                }
                .padding(.horizontal, LumaSpacing.md)
                .padding(.top, LumaSpacing.md)
                .padding(.bottom, LumaSpacing.sm)
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: LumaSpacing.sm) {
            Text("Чем помочь?")
                .font(LumaType.display(30))
                .foregroundStyle(LumaColor.textPrimary)
            Text("Опишите задачу — Luma подберёт подходящие инструменты и подтвердит рискованные действия перед выполнением.")
                .font(LumaType.subheadline)
                .foregroundStyle(LumaColor.textSecondary)
        }
        .padding(.top, LumaSpacing.xl)
        .padding(.bottom, LumaSpacing.lg)
    }

    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
        switch message.role {
        case .user:
            UserBubble(text: message.text)
        case .assistant:
            AssistantBubble(text: message.text, isStreaming: message.isStreaming)
        case .toolAction:
            if let action = message.toolAction {
                ToolActionCardView(action: action)
            }
        case .richCard:
            if let card = message.richCard {
                RichAnswerCardView(card: card)
            }
        case .widgets:
            if let widgets = message.widgets, !widgets.isEmpty {
                AnswerWidgetGridView(widgets: widgets)
            }
        }
    }

    /// Siri-style input bar: three separate elements (not one fused capsule)
    /// — a standalone "+" circle opening model/intelligence controls (per
    /// DESIGN.md there is no microphone — everything that used to sit in a
    /// chip row above the field now lives behind "+"), a prominent pill text
    /// field, and a standalone round send/stop button.
    private var inputBar: some View {
        LumaGlass.container(spacing: LumaSpacing.xs) {
            HStack(alignment: .center, spacing: LumaSpacing.xs) {
                Menu {
                    Button {
                        showModelPicker = true
                    } label: {
                        Label(appState.selectedModel().name, systemImage: "cube.fill")
                    }
                    Button {
                        showIntelligencePicker = true
                    } label: {
                        Label(appState.intelligenceMode.title, systemImage: appState.intelligenceMode.systemImage)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(LumaColor.textPrimary)
                        .frame(width: 44, height: 44)
                        .glassSurface(cornerRadius: LumaRadius.pill)
                }

                TextField("Спросите что-нибудь", text: $draft, axis: .vertical)
                    .font(LumaType.body)
                    .lineLimit(1...5)
                    .focused($inputFocused)
                    .padding(.horizontal, LumaSpacing.md)
                    .padding(.vertical, LumaSpacing.sm)
                    .glassSurface(cornerRadius: LumaRadius.pill)

                Button {
                    if isGenerating {
                        stopGeneration()
                    } else {
                        sendMessage()
                    }
                } label: {
                    Image(systemName: isGenerating ? "stop.fill" : "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(LumaColor.onAccent)
                        .frame(width: 44, height: 44)
                        .background(
                            isGenerating || canSend ? LumaColor.accent : LumaColor.textTertiary.opacity(0.3),
                            in: Circle()
                        )
                }
                .disabled(!isGenerating && !canSend)
            }
        }
        .padding(.horizontal, LumaSpacing.md)
        .padding(.top, LumaSpacing.xs)
        .padding(.bottom, LumaSpacing.xs)
    }

    private func loadMessages() {
        messages = conversation?.messages ?? []
    }

    private func sendMessage() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        inputFocused = false
        messages.append(ChatMessage(id: UUID(), role: .user, text: text, createdAt: .now))
        simulateAssistantReply()
    }

    private func stopGeneration() {
        isGenerating = false
        status = .idle
        if let idx = messages.lastIndex(where: { $0.isStreaming }) {
            messages[idx].isStreaming = false
        }
    }

    private func simulateAssistantReply() {
        isGenerating = true
        status = .thinking
        let replyID = UUID()
        let reply = MockReplyGenerator.reply(for: messages.last?.text ?? "")
        let introText: String
        let trailingWidgets: [AnswerWidget]?
        switch reply {
        case .text(let text):
            introText = text
            trailingWidgets = nil
        case .widgets(let intro, let widgets):
            introText = intro
            trailingWidgets = widgets
        }

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard isGenerating else { return }
            await MainActor.run {
                status = .generating
                messages.append(ChatMessage(id: replyID, role: .assistant, text: "", createdAt: .now, isStreaming: true))
            }

            var shown = ""
            for character in introText {
                try? await Task.sleep(nanoseconds: 18_000_000)
                guard isGenerating else { return }
                shown.append(character)
                let snapshot = shown
                await MainActor.run {
                    if let idx = messages.firstIndex(where: { $0.id == replyID }) {
                        messages[idx].text = snapshot
                    }
                }
            }
            await MainActor.run {
                if let idx = messages.firstIndex(where: { $0.id == replyID }) {
                    messages[idx].isStreaming = false
                }
                if let trailingWidgets {
                    messages.append(ChatMessage(id: UUID(), role: .widgets, text: "", createdAt: .now, widgets: trailingWidgets))
                }
                isGenerating = false
                status = .idle
            }
        }
    }
}

/// Stage 1 has no real agent yet, but this stands in for the moment a real
/// run would call `get_device_status` and decide the result reads better as
/// a native widget than as prose — the same `AnswerWidget` catalog a real
/// agent will compose from later (see ARCHITECTURE.md).
private enum MockReply {
    case text(String)
    case widgets(intro: String, widgets: [AnswerWidget])
}

private enum MockReplyGenerator {
    static func reply(for prompt: String) -> MockReply {
        let lower = prompt.lowercased()
        let asksBattery = lower.contains("процент") || lower.contains("батаре") || lower.contains("заряд")
        let asksStorage = lower.contains("память") || lower.contains("хранилищ") || lower.contains("места") || lower.contains("диск")

        if asksBattery && asksStorage {
            return .widgets(intro: "Вот текущий статус устройства:", widgets: [batteryWidget(kind: .squareTile), storageWidget(kind: .squareTile)])
        }
        if asksBattery {
            return .widgets(intro: "Сейчас на iPhone:", widgets: [batteryWidget(kind: .compactMetric)])
        }
        if asksStorage {
            return .widgets(intro: "Свободное место на устройстве:", widgets: [storageWidget(kind: .compactMetric)])
        }
        return .text("Это демонстрационный ответ на моковых данных. На Этапе 1 модель ещё не подключена — здесь показывается потоковая генерация текста и общий вид интерфейса.")
    }

    /// Matches the real Battery widget's color rule: white/monochrome by
    /// default, green only while charging, red only when critically low —
    /// never a green ring just because the level happens to be high.
    private static func batteryWidget(kind: AnswerWidgetKind) -> AnswerWidget {
        let snapshot = DiagnosticsSnapshot()
        let fraction = Double(snapshot.batteryPercent) / 100.0
        let tint: AnswerWidgetTint = snapshot.isCharging ? .success : (snapshot.batteryPercent <= 20 ? .danger : .neutral)
        return AnswerWidget(
            id: UUID(),
            kind: kind,
            symbolName: "iphone",
            badgeSymbolName: snapshot.isCharging ? "bolt.fill" : nil,
            progress: fraction,
            tint: tint,
            valueText: "\(snapshot.batteryPercent) %",
            detailText: nil,
            caption: "Аккумулятор"
        )
    }

    private static func storageWidget(kind: AnswerWidgetKind) -> AnswerWidget {
        let snapshot = DiagnosticsSnapshot()
        let fraction = snapshot.storageAvailableGB / snapshot.storageTotalGB
        return AnswerWidget(
            id: UUID(),
            kind: kind,
            symbolName: "internaldrive.fill",
            badgeSymbolName: nil,
            progress: fraction,
            tint: .neutral,
            valueText: "\(Int(snapshot.storageAvailableGB)) ГБ",
            detailText: nil,
            caption: "Свободно"
        )
    }
}

#Preview {
    NavigationStack {
        ChatView(path: .constant(NavigationPath()), conversationID: Conversation.mockList[0].id)
    }
    .environment(AppState())
}

struct StatusIndicatorView: View {
    var label: String

    var body: some View {
        HStack(spacing: LumaSpacing.xs) {
            ProgressView()
                .controlSize(.mini)
            Text(label)
                .font(LumaType.footnote)
                .foregroundStyle(LumaColor.textSecondary)
        }
        .padding(.horizontal, LumaSpacing.sm)
        .padding(.vertical, LumaSpacing.xs)
        .glassPill()
    }
}
