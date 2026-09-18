import SwiftUI

struct FocusHomeView: View {

    init(
        focusSessionStore: FocusSessionStore
    ) {
        _focusSessionStore = ObservedObject(
            wrappedValue: focusSessionStore
        )
    }

    private enum Mode: String, CaseIterable, Identifiable {
        case focus
        case relax

        var id: Self {
            self
        }

        var title: String {
            switch self {
            case .focus:
                "Focus"
            case .relax:
                "Relax"
            }
        }

        var eyebrow: String {
            switch self {
            case .focus:
                "Focus Mode"
            case .relax:
                "Relax Mode"
            }
        }

        var heading: String {
            switch self {
            case .focus:
                "Protect your attention."
            case .relax:
                "Give your mind a break."
            }
        }

        var subtitle: String {
            switch self {
            case .focus:
                "Stay with one thing at a time and work with intention."
            case .relax:
                "Use the timer freely. Rest is part of focused work."
            }
        }

        var actionTitle: String {
            switch self {
            case .focus:
                "Start Focus"
            case .relax:
                "Start Relax"
            }
        }
    }

    @Environment(\.scenePhase) private var scenePhase

    @State private var mode: Mode = .focus
    @State private var task = ""
    @State private var settings = SettingsStore()
    @State private var timerEngine: TimerEngine?
    @ObservedObject private var focusSessionStore: FocusSessionStore
    @State private var timerRefreshDate = Date()
    @State private var interruptionStartedAt: Date?
    @State private var interruptedDurationSeconds = 0

    // Focus and Relax keep their own selected duration.
    @State private var focusDurationSelection: TimerDurationSelection?
    @State private var relaxDurationSelection: TimerDurationSelection?

    private let durationDefaults = UserDefaults.standard


    private enum DurationStorageKey {
        static let focus = "focura.timer.duration.focus"
        static let relax = "focura.timer.duration.relax"
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 24
            ) {
                introSection

                modeSelector

                if mode == .focus {
                    taskSection
                }

                durationSection

                timerSection

                if mode == .focus {
                    integritySection
                }

                philosophySection
            }
            .frame(
                maxWidth: 720,
                alignment: .leading
            )
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .scrollIndicators(.hidden)
        .background(
            FocuraColors.surface
                .ignoresSafeArea()
        )
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            initializeDurationSelectionsIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .task(id: timerEngine?.state.expectedEndAt) {
            await monitorTimerCompletion()
        }
    }

    private var introSection: some View {
        VStack(
            alignment: .leading,
            spacing: 7
        ) {
            Text(mode.eyebrow)
                .font(FocuraTypography.captionMedium)
                .foregroundStyle(FocuraColors.primary)

            Text(mode.heading)
                .font(FocuraTypography.pageTitle)
                .foregroundStyle(FocuraColors.textPrimary)
                .tracking(-0.7)
                .fixedSize(horizontal: false, vertical: true)

            Text(mode.subtitle)
                .font(FocuraTypography.body)
                .foregroundStyle(FocuraColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var modeSelector: some View {
        HStack(spacing: 4) {
            ForEach(Mode.allCases) { item in
                Button {
                    guard timerDisplayStatus(at: timerRefreshDate) != .running,
                          timerDisplayStatus(at: timerRefreshDate) != .paused else {
                        return
                    }

                    withAnimation(.easeInOut(duration: 0.18)) {
                        mode = item
                        timerEngine = nil
                        timerRefreshDate = Date()
                    }
                } label: {
                    Text(item.title)
                        .font(FocuraTypography.bodyMedium)
                        .foregroundStyle(
                            mode == item
                                ? .white
                                : FocuraColors.textSecondary
                        )
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 44
                        )
                        .background(
                            mode == item
                                ? FocuraColors.primary
                                : .clear
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(
                    "focus.mode.\(item.rawValue)"
                )
                .accessibilityAddTraits(
                    mode == item ? .isSelected : []
                )
            }
        }
        .padding(4)
        .background(
            Color(uiColor: .secondarySystemBackground)
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(
                FocuraColors.border,
                lineWidth: 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }

    private var taskSection: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("What are you focusing on?")
                .font(FocuraTypography.bodyMedium)
                .foregroundStyle(FocuraColors.textPrimary)

            TextField(
                "e.g. Finish project documentation",
                text: $task
            )
            .font(FocuraTypography.body)
            .textFieldStyle(.plain)
            .textInputAutocapitalization(.sentences)
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(
                Color(uiColor: .secondarySystemBackground)
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    FocuraColors.border,
                    lineWidth: 1
                )
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
            .accessibilityIdentifier("focus.task")
        }
    }

    private var durationSection: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("Duration")
                .font(FocuraTypography.bodyMedium)
                .foregroundStyle(FocuraColors.textPrimary)

            HStack(spacing: 8) {
                ForEach(durationOptions, id: \.id) { option in
                    Button {
                        selectDurationOption(option)
                    } label: {
                        Text(option.label)
                            .font(FocuraTypography.captionMedium)
                            .foregroundStyle(
                                isDurationOptionSelected(option)
                                    ? FocuraColors.primary
                                    : FocuraColors.textSecondary
                            )
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 44
                            )
                            .background(
                                isDurationOptionSelected(option)
                                    ? FocuraColors.primaryTint
                                    : Color(uiColor: .secondarySystemBackground)
                            )
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 14,
                                    style: .continuous
                                )
                                .stroke(
                                    isDurationOptionSelected(option)
                                        ? FocuraColors.primary
                                        : FocuraColors.border,
                                    lineWidth: 1
                                )
                            }
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 14,
                                    style: .continuous
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(
                        timerDisplayStatus(at: timerRefreshDate) == .running
                        || timerDisplayStatus(at: timerRefreshDate) == .paused
                    )
                    .accessibilityIdentifier(
                        "focus.duration.\(option.id)"
                    )
                    .accessibilityAddTraits(
                        isDurationOptionSelected(option)
                            ? .isSelected
                            : []
                    )
                }
            }

            if isUsingCustomDuration {
                HStack(spacing: 8) {
                    TextField(
                        "Custom duration",
                        value: customMinutesBinding,
                        format: .number
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(FocuraTypography.bodyMedium)
                    .foregroundStyle(FocuraColors.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 44
                    )
                    .background(
                        Color(uiColor: .secondarySystemBackground)
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                        .stroke(
                            FocuraColors.border,
                            lineWidth: 1
                        )
                    }
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                    )
                    .accessibilityIdentifier("focus.duration.custom.input")

                    Text("minutes")
                        .font(FocuraTypography.caption)
                        .foregroundStyle(FocuraColors.textSecondary)
                }
                .transition(.opacity)
            }
        }
    }

    private struct DurationOption: Identifiable {
        let id: String
        let label: String
        let minutes: Int?
    }

    private var configuredDurationForCurrentMode: Int {
        switch mode {
        case .focus:
            return settings.focusDurationMinutes

        case .relax:
            return settings.shortBreakDurationMinutes
        }
    }

    private var currentDurationSelection: TimerDurationSelection {
        switch mode {
        case .focus:
            return focusDurationSelection
                ?? TimerDurationSelection(
                    configuredMinutes: settings.focusDurationMinutes
                )

        case .relax:
            return relaxDurationSelection
                ?? TimerDurationSelection(
                    configuredMinutes: settings.shortBreakDurationMinutes
                )
        }
    }

    private var durationOptions: [DurationOption] {
        [
            DurationOption(
                id: "configured",
                label: "\(configuredDurationForCurrentMode) min",
                minutes: configuredDurationForCurrentMode
            ),
            DurationOption(
                id: "45",
                label: "45 min",
                minutes: 45
            ),
            DurationOption(
                id: "50",
                label: "50 min",
                minutes: 50
            ),
            DurationOption(
                id: "custom",
                label: "Custom",
                minutes: nil
            )
        ]
    }

    private var selectedDurationMinutes: Int {
        currentDurationSelection.selectedMinutes
    }

    private var isUsingCustomDuration: Bool {
        currentDurationSelection.usesCustom
    }

    private var customMinutesBinding: Binding<Int> {
        Binding(
            get: {
                currentDurationSelection.selectedMinutes
            },
            set: { value in
                guard timerDisplayStatus(at: timerRefreshDate) == .idle else {
                    return
                }

                switch mode {
                case .focus:
                    guard var selection = focusDurationSelection else {
                        return
                    }

                    selection.updateCustom(value)
                    focusDurationSelection = selection
                    persistDurationSelection(
                        selection,
                        key: DurationStorageKey.focus
                    )

                case .relax:
                    guard var selection = relaxDurationSelection else {
                        return
                    }

                    selection.updateCustom(value)
                    relaxDurationSelection = selection
                    persistDurationSelection(
                        selection,
                        key: DurationStorageKey.relax
                    )
                }

                timerEngine = nil
                timerRefreshDate = Date()
            }
        )
    }

    private func initializeDurationSelectionsIfNeeded() {
        if focusDurationSelection == nil {
            focusDurationSelection = loadDurationSelection(
                key: DurationStorageKey.focus,
                configuredMinutes: settings.focusDurationMinutes
            )
        }

        if relaxDurationSelection == nil {
            relaxDurationSelection = loadDurationSelection(
                key: DurationStorageKey.relax,
                configuredMinutes: settings.shortBreakDurationMinutes
            )
        }
    }

    private func loadDurationSelection(
        key: String,
        configuredMinutes: Int
    ) -> TimerDurationSelection {
        guard let data = durationDefaults.data(forKey: key),
              let stored = try? JSONDecoder().decode(
                  TimerDurationSelection.self,
                  from: data
              ) else {
            return TimerDurationSelection(
                configuredMinutes: configuredMinutes
            )
        }

        return stored
    }

    private func persistDurationSelection(
        _ selection: TimerDurationSelection,
        key: String
    ) {
        guard let data = try? JSONEncoder().encode(selection) else {
            return
        }

        durationDefaults.set(data, forKey: key)
    }

    private func isDurationOptionSelected(
        _ option: DurationOption
    ) -> Bool {
        if option.minutes == nil {
            return isUsingCustomDuration
        }

        return !isUsingCustomDuration
            && selectedDurationMinutes == option.minutes
    }

    private func selectDurationOption(
        _ option: DurationOption
    ) {
        let status = timerDisplayStatus(at: timerRefreshDate)

        guard status == .idle || status == .completed else {
            return
        }

        switch mode {
        case .focus:
            var selection = focusDurationSelection
                ?? TimerDurationSelection(
                    configuredMinutes: settings.focusDurationMinutes
                )

            if let minutes = option.minutes {
                selection.selectPreset(minutes)
            } else {
                selection.selectCustom(
                    selection.selectedMinutes
                )
            }

            focusDurationSelection = selection
            persistDurationSelection(
                selection,
                key: DurationStorageKey.focus
            )

        case .relax:
            var selection = relaxDurationSelection
                ?? TimerDurationSelection(
                    configuredMinutes: settings.shortBreakDurationMinutes
                )

            if let minutes = option.minutes {
                selection.selectPreset(minutes)
            } else {
                selection.selectCustom(
                    selection.selectedMinutes
                )
            }

            relaxDurationSelection = selection
            persistDurationSelection(
                selection,
                key: DurationStorageKey.relax
            )
        }

        timerEngine = nil
        timerRefreshDate = Date()
    }

    private var timerSection: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let status = timerDisplayStatus(at: context.date)
            let remainingSeconds = timerDisplayRemainingSeconds(
                at: context.date
            )

            VStack(
                alignment: .leading,
                spacing: 20
            ) {
                VStack(
                    alignment: .center,
                    spacing: 10
                ) {
                    Text(statusTitle(status))
                        .font(FocuraTypography.captionMedium)
                        .foregroundStyle(FocuraColors.textSecondary)
                        .frame(maxWidth: .infinity)

                    Text(formattedTime(remainingSeconds))
                        .font(FocuraTypography.timer)
                        .monospacedDigit()
                        .foregroundStyle(FocuraColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(
                            timerAccessibilityLabel(
                                remainingSeconds: remainingSeconds
                            )
                        )
                        .accessibilityIdentifier("focus.timer")

                    Text(timerSubtitle(status))
                        .font(FocuraTypography.caption)
                        .foregroundStyle(FocuraColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                timerControls(status)
            }
            .padding(.vertical, 8)
        }
        .task(id: timerEngine?.state.expectedEndAt) {
            await monitorTimerCompletion()
        }
    }

    private var configuredDurationMinutes: Int {
        selectedDurationMinutes
    }

    private var currentTimerMode: TimerMode {
        switch mode {
        case .focus:
            return .focus

        case .relax:
            return .relax
        }
    }

    private func timerDisplayStatus(
        at date: Date
    ) -> TimerStatus {
        guard let timerEngine else {
            return .idle
        }

        if timerEngine.state.status == .running,
           timerEngine.remainingSeconds(at: date) == 0 {
            return .completed
        }

        return timerEngine.state.status
    }

    private func timerDisplayRemainingSeconds(
        at date: Date
    ) -> Int {
        guard let timerEngine else {
            return configuredDurationMinutes * 60
        }

        return timerEngine.remainingSeconds(at: date)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let clampedSeconds = max(0, seconds)
        let minutes = clampedSeconds / 60
        let remainingSeconds = clampedSeconds % 60

        return String(
            format: "%02d:%02d",
            minutes,
            remainingSeconds
        )
    }

    private func timerAccessibilityLabel(
        remainingSeconds: Int
    ) -> String {
        let clampedSeconds = max(0, remainingSeconds)
        let minutes = clampedSeconds / 60
        let seconds = clampedSeconds % 60

        if minutes == 0 {
            return "\(seconds) seconds remaining"
        }

        if seconds == 0 {
            return "\(minutes) minutes remaining"
        }

        return "\(minutes) minutes \(seconds) seconds remaining"
    }

    private func statusTitle(
        _ status: TimerStatus
    ) -> String {
        switch status {
        case .idle:
            "Ready"

        case .running:
            "Running"

        case .paused:
            "Paused"

        case .completed:
            "Completed"
        }
    }

    private func timerSubtitle(
        _ status: TimerStatus
    ) -> String {
        switch status {
        case .idle:
            mode == .focus
                ? "Ready to focus"
                : "Ready to relax"

        case .running:
            mode == .focus
                ? "Stay with your work."
                : "Take your time."

        case .paused:
            "Timer paused."

        case .completed:
            mode == .focus
                ? "Focus session complete."
                : "Relax session complete."
        }
    }

    @ViewBuilder
    private func timerControls(
        _ status: TimerStatus
    ) -> some View {
        switch status {
        case .idle:
            Button {
                startTimer()
            } label: {
                Label(
                    mode.actionTitle,
                    systemImage: "play.fill"
                )
            }
            .buttonStyle(FocuraPrimaryButtonStyle())
            .accessibilityIdentifier("focus.start")

        case .running:
            Button {
                pauseTimer()
            } label: {
                Label(
                    "Pause",
                    systemImage: "pause.fill"
                )
            }
            .buttonStyle(FocuraPrimaryButtonStyle())
            .accessibilityIdentifier("focus.pause")

        case .paused:
            HStack(spacing: 10) {
                Button {
                    resumeTimer()
                } label: {
                    Label(
                        "Resume",
                        systemImage: "play.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(FocuraPrimaryButtonStyle())
                .accessibilityIdentifier("focus.resume")

                Button {
                    resetTimer()
                } label: {
                    Label(
                        "Reset",
                        systemImage: "arrow.counterclockwise"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(FocuraDarkButtonStyle())
                .accessibilityIdentifier("focus.reset")
            }

        case .completed:
            Button {
                resetTimer()
            } label: {
                Label(
                    "Start Again",
                    systemImage: "arrow.counterclockwise"
                )
            }
            .buttonStyle(FocuraPrimaryButtonStyle())
            .accessibilityIdentifier("focus.reset")
        }
    }

    private func handleScenePhaseChange(
        _ phase: ScenePhase
    ) {
        guard settings.interruptionTrackingEnabled,
              mode == .focus,
              focusSessionStore.isActive,
              timerEngine?.state.status == .running
        else {
            return
        }

        switch phase {
        case .background, .inactive:
            guard interruptionStartedAt == nil else {
                return
            }

            interruptionStartedAt = Date()

        case .active:
            /*
             * Reconcile the local timer against its timestamp before
             * recording an interruption. If the deadline passed while
             * the app was inactive/backgrounded, the timer is completed
             * rather than treating post-deadline time as an interruption.
             */
            timerEngine?.update()

            if timerEngine?.state.status == .completed {
                interruptionStartedAt = nil
                timerRefreshDate = Date()
                return
            }

            guard let startedAt = interruptionStartedAt else {
                return
            }

            interruptionStartedAt = nil

            let endedAt = Date()
            interruptedDurationSeconds += max(
                0,
                Int(endedAt.timeIntervalSince(startedAt))
            )

            let store = focusSessionStore

            Task { @MainActor in
                _ = await store.recordInterruption(
                    startedAt: startedAt,
                    endedAt: endedAt
                )
            }

        @unknown default:
            break
        }
    }

    private func startTimer() {
    guard timerEngine == nil
            || timerEngine?.state.status == .idle
            || timerEngine?.state.status == .completed
    else {
        return
    }

    guard !focusSessionStore.hasServerSession,
          !focusSessionStore.isCreating
    else {
        return
    }

    interruptionStartedAt = nil
    interruptedDurationSeconds = 0

    let startedAt = Date()
    let plannedDurationSeconds =
        selectedDurationMinutes * 60
    let timerMode = currentTimerMode

    let title =
        timerMode == .focus
        ? task.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        : nil

    let engine = TimerEngine(
        mode: timerMode,
        durationSeconds: plannedDurationSeconds
    )

    /*
     * The timer is the source of truth for the local UI.
     * Backend synchronization must never control the timer
     * lifecycle.
     */
    do {
        try engine.start()
    } catch {
        return
    }

    timerEngine = engine
    timerRefreshDate = Date()

    /*
     * Backend session creation is completely detached from
     * the local timer lifecycle.
     *
     * A backend failure must NOT reset, pause, or otherwise
     * modify the local timer.
     */
    let store = focusSessionStore

    Task { @MainActor in
        _ = await store.start(
            mode: timerMode,
            title: title,
            plannedDurationSeconds: plannedDurationSeconds,
            startedAt: startedAt
        )
    }
}

    private func pauseTimer() {
    guard let engine = timerEngine,
          engine.state.status == .running
    else {
        return
    }

    /*
     * Pause locally first.
     */
    do {
        try engine.pause()
    } catch {
        return
    }

    timerRefreshDate = Date()

    /*
     * Backend synchronization is secondary.
     * It can never change the local timer state.
     */
    let timestamp = Date()
    let store = focusSessionStore

    Task { @MainActor in
        await store.waitForCreation()

        guard store.hasServerSession else {
            return
        }

        _ = await store.pause(at: timestamp)
    }
}

    private func resumeTimer() {
    guard let engine = timerEngine,
          engine.state.status == .paused
    else {
        return
    }

    /*
     * Resume locally first.
     */
    do {
        try engine.resume()
    } catch {
        return
    }

    timerRefreshDate = Date()

    /*
     * Backend synchronization is secondary.
     * It can never change the local timer state.
     */
    let timestamp = Date()
    let store = focusSessionStore

    Task { @MainActor in
        await store.waitForCreation()

        guard store.hasServerSession else {
            return
        }

        _ = await store.resume(at: timestamp)
    }
}

    private func resetTimer() {
    let store = focusSessionStore
    let previousSessionID = store.session?.id

    /*
     * Reset is purely local first.
     *
     * TimerEngine.reset() returns the timer to idle and
     * restores the original duration automatically.
     */
    guard let engine = timerEngine else {
        timerRefreshDate = Date()
        return
    }

    do {
        try engine.reset()
    } catch {
        return
    }

    interruptionStartedAt = nil
    interruptedDurationSeconds = 0
    timerRefreshDate = Date()

    /*
     * Backend cancellation is optional synchronization.
     * It must never affect the local reset.
     */
    guard let sessionID = previousSessionID else {
        return
    }

    Task { @MainActor in
        await store.waitForCreation()

        _ = await store.cancel(
            sessionID: sessionID,
            at: Date()
        )
    }
}

    private func monitorTimerCompletion() async {
        guard let timerEngine,
              let expectedEndAt = timerEngine.state.expectedEndAt,
              timerEngine.state.status == .running
        else {
            return
        }

        let interval = expectedEndAt.timeIntervalSinceNow

        if interval > 0 {
            do {
                try await Task.sleep(
                    for: .seconds(interval)
                )
            } catch {
                return
            }
        }

        guard !Task.isCancelled else {
            return
        }

        timerEngine.update()

        guard timerEngine.state.status == .completed else {
            return
        }

        let store = focusSessionStore
        let completedAt = expectedEndAt

        /*
         * The local timer has already completed. Backend synchronization
         * must wait for the asynchronous session creation if necessary.
         */
        await store.waitForCreation()

        let completed = await store.complete(at: completedAt)

        guard completed else {
            return
        }

        timerRefreshDate = Date()
    }

    private var integritySection: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let metrics = focusIntegrityMetrics(at: context.date)

            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                Text("Focus Integrity")
                    .font(FocuraTypography.sectionTitle)
                    .foregroundStyle(FocuraColors.textPrimary)

                HStack(spacing: 8) {
                    integrityMetric(
                        title: "Integrity",
                        value: String(
                            format: "%.0f%%",
                            metrics.integrity
                        ),
                        tint: FocuraColors.primary
                    )

                    integrityMetric(
                        title: "Focused",
                        value: formattedMetricMinutes(
                            metrics.focusedSeconds
                        ),
                        tint: FocuraColors.success
                    )

                    integrityMetric(
                        title: "Interrupted",
                        value: formattedMetricMinutes(
                            metrics.interruptedSeconds
                        ),
                        tint: FocuraColors.warning
                    )
                }
            }
        }
    }

    private struct FocusIntegrityMetrics {
        let integrity: Double
        let focusedSeconds: Int
        let interruptedSeconds: Int
    }

    private func focusIntegrityMetrics(
        at date: Date
    ) -> FocusIntegrityMetrics {
        let plannedSeconds = max(
            1,
            configuredDurationMinutes * 60
        )

        guard let timerEngine else {
            return FocusIntegrityMetrics(
                integrity: 0,
                focusedSeconds: 0,
                interruptedSeconds: interruptedDurationSeconds
            )
        }

        let elapsedSeconds = timerEngine.elapsedSeconds(
            at: date
        )

        let currentInterruptionSeconds: Int

        if let interruptionStartedAt {
            currentInterruptionSeconds = max(
                0,
                Int(
                    date.timeIntervalSince(
                        interruptionStartedAt
                    )
                )
            )
        } else {
            currentInterruptionSeconds = 0
        }

        let interruptedSeconds = max(
            0,
            interruptedDurationSeconds
                + currentInterruptionSeconds
        )

        let focusedSeconds = min(
            plannedSeconds,
            max(
                0,
                elapsedSeconds - interruptedSeconds
            )
        )

        let integrity = min(
            100,
            max(
                0,
                Double(focusedSeconds)
                    / Double(plannedSeconds)
                    * 100
            )
        )

        return FocusIntegrityMetrics(
            integrity: integrity,
            focusedSeconds: focusedSeconds,
            interruptedSeconds: interruptedSeconds
        )
    }

    private func formattedMetricMinutes(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60

        if minutes == 0 {
            return "\(remainingSeconds)s"
        }

        if remainingSeconds == 0 {
            return "\(minutes)m"
        }

        return "\(minutes)m \(remainingSeconds)s"
    }

    private func integrityMetric(
        title: String,
        value: String,
        tint: Color
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            Text(title)
                .font(FocuraTypography.caption)
                .foregroundStyle(FocuraColors.textSecondary)

            Text(value)
                .font(
                    .system(
                        size: 20,
                        weight: .semibold
                    )
                )
                .monospacedDigit()
                .foregroundStyle(tint)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(14)
        .background(
            Color(uiColor: .secondarySystemBackground)
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(
                FocuraColors.border,
                lineWidth: 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
    }

    private var philosophySection: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("Protect your attention.")
                .font(FocuraTypography.bodyMedium)
                .foregroundStyle(FocuraColors.textPrimary)

            Text(
                "Focura helps you work with intention, notice interruptions, and understand how you spend your focused time."
            )
            .font(FocuraTypography.body)
            .foregroundStyle(FocuraColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }
}

#Preview {
    NavigationStack {
        FocusHomeView(
            focusSessionStore: FocusSessionStore(
                repository: PreviewFocusHomeSessionRepository()
            )
        )
    }
}

private struct PreviewFocusHomeSessionRepository: FocusSessionRepository {
    func list(
        page: Int,
        perPage: Int,
        mode: TimerMode?,
        status: FocusSessionStatus?
    ) async throws -> FocusSessionPage {
        FocusSessionPage(
            data: [],
            currentPage: page,
            lastPage: page,
            perPage: perPage,
            total: 0
        )
    }

    func create(
        mode: TimerMode,
        title: String?,
        plannedDurationSeconds: Int,
        startedAt: Date
    ) async throws -> FocusSession {
        FocusSession(
            id: 1,
            userID: nil,
            visitorID: nil,
            mode: mode,
            title: title,
            plannedDurationSeconds: plannedDurationSeconds,
            actualDurationSeconds: 0,
            focusedDurationSeconds: 0,
            interruptedDurationSeconds: 0,
            interruptionCount: 0,
            focusIntegrity: nil,
            status: .active,
            startedAt: startedAt,
            endedAt: nil,
            interruptions: [],
            createdAt: startedAt,
            updatedAt: startedAt
        )
    }

    func pause(
        sessionID: Int,
        startedAt: Date
    ) async throws -> FocusSession {
        fatalError("Preview only")
    }

    func resume(
        sessionID: Int,
        endedAt: Date
    ) async throws -> FocusSession {
        fatalError("Preview only")
    }

    func complete(
        sessionID: Int,
        endedAt: Date
    ) async throws -> FocusSession {
        fatalError("Preview only")
    }

    func cancel(
        sessionID: Int,
        cancelledAt: Date
    ) async throws -> FocusSession {
        fatalError("Preview only")
    }

    func recordInterruption(
        sessionID: Int,
        startedAt: Date,
        endedAt: Date
    ) async throws -> FocusSessionInterruption {
        fatalError("Preview only")
    }
}

private struct PreviewFocusSessionRepository: FocusSessionRepository {
    func list(
        page: Int,
        perPage: Int,
        mode: TimerMode?,
        status: FocusSessionStatus?
    ) async throws -> FocusSessionPage {
        FocusSessionPage(
            data: [],
            currentPage: page,
            lastPage: page,
            perPage: perPage,
            total: 0
        )
    }

    func create(
        mode: TimerMode,
        title: String?,
        plannedDurationSeconds: Int,
        startedAt: Date
    ) async throws -> FocusSession {
        FocusSession(
            id: 1,
            userID: nil,
            visitorID: UUID().uuidString,
            mode: mode,
            title: title,
            plannedDurationSeconds: plannedDurationSeconds,
            actualDurationSeconds: 0,
            focusedDurationSeconds: 0,
            interruptedDurationSeconds: 0,
            interruptionCount: 0,
            focusIntegrity: nil,
            status: .active,
            startedAt: startedAt,
            endedAt: nil,
            interruptions: [],
            createdAt: startedAt,
            updatedAt: startedAt
        )
    }

    func pause(
        sessionID: Int,
        startedAt: Date
    ) async throws -> FocusSession {
        fatalError("Preview only")
    }

    func resume(
        sessionID: Int,
        endedAt: Date
    ) async throws -> FocusSession {
        fatalError("Preview only")
    }

    func complete(
        sessionID: Int,
        endedAt: Date
    ) async throws -> FocusSession {
        fatalError("Preview only")
    }

    func cancel(
        sessionID: Int,
        cancelledAt: Date
    ) async throws -> FocusSession {
        fatalError("Preview only")
    }

    func recordInterruption(
        sessionID: Int,
        startedAt: Date,
        endedAt: Date
    ) async throws -> FocusSessionInterruption {
        fatalError("Preview only")
    }
}
