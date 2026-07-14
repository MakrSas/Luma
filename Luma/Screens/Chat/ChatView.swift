import SwiftUI
import LocalLLMClient

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
        generateReply(for: text)
    }

    private func stopGeneration() {
        isGenerating = false
        appState.inferenceEngine.cancelGeneration()
        status = .idle
        if let idx = messages.lastIndex(where: { $0.isStreaming }) {
            messages[idx].isStreaming = false
        }
    }

    /// Real reply generation, real tool-calling: the model decides for
    /// itself — via `DeviceTools` structured function-calling, not keyword
    /// matching — whether it needs to check the battery, storage, or iOS
    /// version before answering. See `MLXInferenceEngine.generate` for the
    /// manual agent loop (the library detects tool calls but doesn't
    /// execute or continue on its own).
    private func generateReply(for prompt: String) {
        isGenerating = true
        status = .thinking

        guard appState.selectedModel().downloadState == .installed else {
            let replyID = UUID()
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run {
                    status = .idle
                    isGenerating = false
                    messages.append(ChatMessage(
                        id: replyID,
                        role: .assistant,
                        text: "Скачайте модель в каталоге, чтобы Luma могла отвечать на вопросы. Пока ни одна модель не установлена.",
                        createdAt: .now
                    ))
                }
            }
            return
        }

        let replyID = UUID()
        let history = messages
            .filter { $0.role == .user || $0.role == .assistant }
            .suffix(12)
            .map { (role: $0.role == .user ? InferenceRole.user : .assistant, text: $0.text) }
        let request = InferenceRequest(
            systemPrompt: """
            Ты — полезный локальный ассистент на iPhone. Отвечай кратко и по существу, на русском языке (если пользователь не пишет на другом). Никогда не представляйся названием приложения и не говори «я Luma».
            У тебя есть инструменты для проверки заряда батареи, свободного места и версии iOS — используй их, если вопрос об этом. Для всего остального, чего не можешь проверить (интернет, время, файлы пользователя), честно скажи, что не можешь это проверить, и не придумывай ответ.
            """,
            messages: Array(history)
        )

        Task {
            do {
                let modelURL = ModelDownloader.localDirectory(for: appState.selectedModel())
                try await appState.inferenceEngine.load(modelFileURL: modelURL, tools: DeviceTools.all)
                await MainActor.run {
                    status = .generating
                    messages.append(ChatMessage(id: replyID, role: .assistant, text: "", createdAt: .now, isStreaming: true))
                }
                var calledToolNames: [String] = []
                for try await event in appState.inferenceEngine.generate(request) {
                    guard isGenerating else { return }
                    switch event {
                    case .token(let text):
                        await MainActor.run {
                            status = .generating
                            if let idx = messages.firstIndex(where: { $0.id == replyID }) {
                                messages[idx].text += text
                            }
                        }
                    case .toolCall(let name):
                        calledToolNames.append(name)
                        await MainActor.run { status = .runningTool(DeviceToolWidgets.friendlyName(for: name)) }
                    }
                }
                await MainActor.run {
                    if let idx = messages.firstIndex(where: { $0.id == replyID }) {
                        messages[idx].isStreaming = false
                    }
                    if !calledToolNames.isEmpty {
                        let widgets = DeviceToolWidgets.build(for: calledToolNames)
                        messages.append(ChatMessage(id: UUID(), role: .widgets, text: "", createdAt: .now, widgets: widgets))
                    }
                    isGenerating = false
                    status = .idle
                }
            } catch is CancellationError {
                await MainActor.run {
                    if let idx = messages.firstIndex(where: { $0.id == replyID }) {
                        messages[idx].isStreaming = false
                        if messages[idx].text.isEmpty {
                            messages.remove(at: idx)
                        }
                    }
                    isGenerating = false
                    status = .idle
                }
            } catch {
                await MainActor.run {
                    if let idx = messages.firstIndex(where: { $0.id == replyID }) {
                        messages[idx].text = "Не удалось сгенерировать ответ: \(error.localizedDescription)"
                        messages[idx].isStreaming = false
                    } else {
                        messages.append(ChatMessage(id: replyID, role: .assistant, text: "Не удалось сгенерировать ответ: \(error.localizedDescription)", createdAt: .now))
                    }
                    isGenerating = false
                    status = .idle
                }
            }
        }
    }
}

/// Turns the *names* of tools the model actually chose to call into
/// `AnswerWidget`s — the model's decision is real (see
/// `MLXInferenceEngine`/`DeviceTools`), and so is the data displayed here
/// (a fresh `DeviceStatusProvider` read, not whatever the tool call
/// returned to the model — both come from the same live source, so they
/// agree).
private enum DeviceToolWidgets {
    static func friendlyName(for toolName: String) -> String {
        switch toolName {
        case GetBatteryStatusTool.toolName: return "заряд батареи"
        case GetStorageStatusTool.toolName: return "свободное место"
        case GetSystemVersionTool.toolName: return "версию iOS"
        default: return toolName
        }
    }

    static func build(for toolNames: [String]) -> [AnswerWidget] {
        let kind: AnswerWidgetKind = toolNames.count == 1 ? .compactMetric : .squareTile
        return toolNames.compactMap { name in
            switch name {
            case GetBatteryStatusTool.toolName: return batteryWidget(kind: kind)
            case GetStorageStatusTool.toolName: return storageWidget(kind: kind)
            case GetSystemVersionTool.toolName: return systemVersionWidget(kind: kind)
            default: return nil
            }
        }
    }

    /// Matches the real Battery widget's color rule: white/monochrome by
    /// default, green only while charging, red only when critically low —
    /// never a green ring just because the level happens to be high.
    private static func batteryWidget(kind: AnswerWidgetKind) -> AnswerWidget {
        let status = DeviceStatusProvider.batteryStatus()
        let fraction = Double(status.percent) / 100.0
        let tint: AnswerWidgetTint = status.isCharging ? .success : (status.percent <= 20 ? .danger : .neutral)
        return AnswerWidget(
            id: UUID(),
            kind: kind,
            symbolName: "iphone",
            badgeSymbolName: status.isCharging ? "bolt.fill" : nil,
            progress: fraction,
            tint: tint,
            valueText: "\(status.percent) %",
            detailText: nil,
            caption: "Аккумулятор"
        )
    }

    private static func storageWidget(kind: AnswerWidgetKind) -> AnswerWidget {
        let status = DeviceStatusProvider.storageStatus()
        let fraction = status.totalGB > 0 ? status.freeGB / status.totalGB : 0
        return AnswerWidget(
            id: UUID(),
            kind: kind,
            symbolName: "internaldrive.fill",
            badgeSymbolName: nil,
            progress: fraction,
            tint: .neutral,
            valueText: "\(Int(status.freeGB)) ГБ",
            detailText: nil,
            caption: "Свободно"
        )
    }

    private static func systemVersionWidget(kind: AnswerWidgetKind) -> AnswerWidget {
        AnswerWidget(
            id: UUID(),
            kind: kind,
            symbolName: "gearshape.fill",
            badgeSymbolName: nil,
            progress: nil,
            tint: .neutral,
            valueText: "iOS \(DeviceStatusProvider.systemVersion)",
            detailText: nil,
            caption: "Версия системы"
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
