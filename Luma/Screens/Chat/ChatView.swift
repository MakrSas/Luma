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
    var conversationID: UUID?

    @State private var draft: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var status: AgentStatus = .idle
    @State private var isGenerating = false
    @State private var showModelPicker = false
    @State private var showIntelligencePicker = false
    @FocusState private var inputFocused: Bool

    private var resolvedConversation: Conversation? {
        let id = conversationID ?? appState.activeConversationID
        return appState.conversations.first(where: { $0.id == id })
    }

    private var navTitle: String {
        if appState.isTemporaryChatActive && conversationID == nil {
            return "Временный диалог"
        }
        return resolvedConversation?.title ?? "Luma"
    }

    var body: some View {
        VStack(spacing: 0) {
            messageScroll
            inputArea
        }
        .background(LumaColor.canvas.ignoresSafeArea())
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    path.append(Route.history)
                } label: {
                    Image(systemName: "square.grid.2x2")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        appState.startNewConversation(temporary: false)
                        messages = []
                    } label: {
                        Label("Новый диалог", systemImage: "plus.bubble")
                    }
                    Button {
                        appState.startNewConversation(temporary: true)
                        messages = []
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
        }
    }

    private var inputArea: some View {
        VStack(spacing: LumaSpacing.xs) {
            HStack(spacing: LumaSpacing.xs) {
                Button {
                    showModelPicker = true
                } label: {
                    HStack(spacing: LumaSpacing.xxs) {
                        Image(systemName: "cube.fill")
                        Text(appState.selectedModel().name)
                            .lineLimit(1)
                    }
                    .font(LumaType.caption)
                }
                .lumaGlassButtonStyle()

                Button {
                    showIntelligencePicker = true
                } label: {
                    HStack(spacing: LumaSpacing.xxs) {
                        Image(systemName: appState.intelligenceMode.systemImage)
                        Text(appState.intelligenceMode.title)
                    }
                    .font(LumaType.caption)
                }
                .lumaGlassButtonStyle()

                Spacer()
            }
            .padding(.horizontal, LumaSpacing.md)

            LumaGlass.container {
                HStack(alignment: .bottom, spacing: LumaSpacing.xs) {
                    TextField("Спросите что-нибудь", text: $draft, axis: .vertical)
                        .font(LumaType.body)
                        .lineLimit(1...5)
                        .focused($inputFocused)
                        .padding(.vertical, LumaSpacing.xs)
                        .padding(.leading, LumaSpacing.sm)

                    sendButton
                        .padding(.trailing, LumaSpacing.xxs)
                        .padding(.bottom, 4)
                }
                .padding(.vertical, LumaSpacing.xxs)
                .glassSurface(cornerRadius: LumaRadius.large)
            }
            .padding(.horizontal, LumaSpacing.md)
            .padding(.bottom, LumaSpacing.xs)
        }
        .padding(.top, LumaSpacing.xs)
        .sheet(isPresented: $showModelPicker) {
            ModelPickerSheet()
        }
        .sheet(isPresented: $showIntelligencePicker) {
            IntelligencePickerSheet()
        }
    }

    private var sendButton: some View {
        Button {
            if isGenerating {
                stopGeneration()
            } else {
                sendMessage()
            }
        } label: {
            Image(systemName: isGenerating ? "stop.fill" : "arrow.up")
                .font(.system(size: 15, weight: .bold))
                .frame(width: 32, height: 32)
        }
        .lumaGlassProminentButtonStyle()
        .disabled(!isGenerating && draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private func loadMessages() {
        messages = resolvedConversation?.messages ?? []
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
        let fullReply = MockReplyGenerator.reply(for: messages.last?.text ?? "")

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard isGenerating else { return }
            await MainActor.run {
                status = .generating
                messages.append(ChatMessage(id: replyID, role: .assistant, text: "", createdAt: .now, isStreaming: true))
            }

            var shown = ""
            for character in fullReply {
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
                isGenerating = false
                status = .idle
            }
        }
    }
}

private enum MockReplyGenerator {
    static func reply(for prompt: String) -> String {
        "Это демонстрационный ответ на моковых данных. На Этапе 1 модель ещё не подключена — здесь показывается потоковая генерация текста и общий вид интерфейса."
    }
}

#Preview {
    NavigationStack {
        ChatView(path: .constant(NavigationPath()))
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
