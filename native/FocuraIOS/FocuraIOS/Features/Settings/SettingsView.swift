import SwiftUI
import UserNotifications

struct SettingsView: View {
    let user: AuthUser

    @Environment(AuthenticationState.self) private var authenticationState

    @StateObject private var settings = SettingsStore()

    @State private var feedbackMessage: String?
    @State private var notificationError: String?
    @State private var showingResetConfirmation = false
    @State private var showingLogoutConfirmation = false
    @State private var showingDurationPicker: DurationPicker?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if let feedbackMessage {
                    feedback(message: feedbackMessage)
                }

                accountSection
                appearanceSection
                timerSection
                focusSection
                notificationSection
                resetSection
            }
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(FocuraColors.surface)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Reset settings?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset to Defaults", role: .destructive) {
                settings.reset()
                showFeedback("Settings restored to defaults.")
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your preferences will be restored to their default values.")
        }
        .alert(
            "Log out of Focura?",
            isPresented: $showingLogoutConfirmation
        ) {
            Button("Log Out", role: .destructive) {
                Task {
                    await authenticationState.logout()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your local preferences will remain on this device.")
        }
        .sheet(item: $showingDurationPicker) { picker in
            DurationPickerSheet(
                title: picker.title,
                range: picker.range,
                initialValue: picker.value,
                onSave: picker.onSave
            )
            .presentationDetents([.height(330)])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preferences")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FocuraColors.primary)

            Text("Settings")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(FocuraColors.textPrimary)
                .tracking(-0.6)

            Text("Your preferences are stored locally on this device.")
                .font(.subheadline)
                .foregroundStyle(FocuraColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    private var accountSection: some View {
        SettingsSectionView(
            title: "Account",
            description: "Manage your Focura account on this device."
        ) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                        .foregroundStyle(FocuraColors.primary)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(user.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(FocuraColors.textPrimary)

                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(FocuraColors.textSecondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)

                Divider()
                    .padding(.vertical, 8)

                Button {
                    showingLogoutConfirmation = true
                } label: {
                    HStack {
                        Text("Log out")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.red)

                        Spacer()

                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.logout")
            }
        }
    }

    private var appearanceSection: some View {
        SettingsSectionView(
            title: "Appearance",
            description: "Choose the interface appearance that feels comfortable for your workspace."
        ) {
            Picker(
                "Appearance",
                selection: Binding(
                    get: { settings.appearance },
                    set: {
                        settings.setAppearance($0)
                        showFeedback("\($0.title) appearance enabled.")
                    }
                )
            ) {
                ForEach(FocuraAppearance.allCases, id: \.self) { appearance in
                    Text(appearance.title)
                        .tag(appearance)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("settings.appearance")
        }
    }

    private var timerSection: some View {
        SettingsSectionView(
            title: "Timer",
            description: "Configure the default duration used when starting a new timer."
        ) {
            VStack(spacing: 0) {
                durationRow(
                    title: "Focus",
                    value: settings.focusDurationMinutes,
                    range: 1...180
                ) {
                    settings.setFocusDurationMinutes($0)
                    showFeedback("Focus duration saved.")
                }

                Divider()

                durationRow(
                    title: "Short break",
                    value: settings.shortBreakDurationMinutes,
                    range: 1...60
                ) {
                    settings.setShortBreakDurationMinutes($0)
                    showFeedback("Short break duration saved.")
                }

                Divider()

                durationRow(
                    title: "Long break",
                    value: settings.longBreakDurationMinutes,
                    range: 1...120
                ) {
                    settings.setLongBreakDurationMinutes($0)
                    showFeedback("Long break duration saved.")
                }
            }

            Text("Changes apply to the next timer. An active or paused timer is not changed.")
                .font(.caption)
                .foregroundStyle(FocuraColors.textTertiary)
                .padding(.top, 12)
        }
    }

    private func durationRow(
        title: String,
        value: Int,
        range: ClosedRange<Int>,
        onSave: @escaping (Int) -> Void
    ) -> some View {
        Button {
            showingDurationPicker = DurationPicker(
                title: title,
                value: value,
                range: range,
                onSave: onSave
            )
        } label: {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FocuraColors.textPrimary)

                Spacer()

                Text("\(value) min")
                    .font(.subheadline)
                    .foregroundStyle(FocuraColors.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FocuraColors.textTertiary)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var focusSection: some View {
        SettingsSectionView(
            title: "Focus",
            description: "Configure how Focura measures interruptions during Focus Mode."
        ) {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Interruption tracking",
                    description: "Track when you leave Focura during a Focus session.",
                    isOn: Binding(
                        get: { settings.interruptionTrackingEnabled },
                        set: {
                            settings.setInterruptionTrackingEnabled($0)
                            showFeedback(
                                $0
                                ? "Interruption tracking enabled."
                                : "Interruption tracking disabled."
                            )
                        }
                    )
                )

                Divider()

                SettingsToggleRow(
                    title: "Interruption warnings",
                    description: "Show a warning when you return after an interruption.",
                    isOn: Binding(
                        get: { settings.interruptionWarningEnabled },
                        set: {
                            settings.setInterruptionWarningEnabled($0)
                            showFeedback(
                                $0
                                ? "Interruption warnings enabled."
                                : "Interruption warnings disabled."
                            )
                        }
                    )
                )
            }
        }
    }

    private var notificationSection: some View {
        SettingsSectionView(
            title: "Notifications & Audio",
            description: "Choose how Focura should notify you when a session finishes."
        ) {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Completion notification",
                    description: "Show a notification when a timer completes.",
                    isOn: Binding(
                        get: { settings.completionNotificationEnabled },
                        set: { value in
                            Task {
                                await toggleNotifications(value)
                            }
                        }
                    )
                )

                if let notificationError {
                    Text(notificationError)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)
                }

                Divider()

                SettingsToggleRow(
                    title: "Completion sound",
                    description: "Play a short sound when a timer completes.",
                    isOn: Binding(
                        get: { settings.completionSoundEnabled },
                        set: {
                            settings.setCompletionSoundEnabled($0)
                            showFeedback(
                                $0
                                ? "Completion sound enabled."
                                : "Completion sound disabled."
                            )
                        }
                    )
                )

                Divider()

                SettingsToggleRow(
                    title: "Interruption warning sound",
                    description: "Play a subtle sound when you return after an interruption.",
                    isOn: Binding(
                        get: { settings.interruptionWarningSoundEnabled },
                        set: {
                            settings.setInterruptionWarningSoundEnabled($0)
                            showFeedback(
                                $0
                                ? "Interruption warning sound enabled."
                                : "Interruption warning sound disabled."
                            )
                        }
                    )
                )
            }
        }
    }

    private var resetSection: some View {
        Button {
            showingResetConfirmation = true
        } label: {
            Text("Reset Defaults")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("settings.reset")
    }

    private func feedback(message: String) -> some View {
        Text(message)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.green)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(.green.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .accessibilityIdentifier("settings.feedback")
    }

    private func showFeedback(_ message: String) {
        feedbackMessage = message

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))

            if feedbackMessage == message {
                feedbackMessage = nil
            }
        }
    }

    private func toggleNotifications(_ enabled: Bool) async {
        notificationError = nil

        if !enabled {
            settings.setCompletionNotificationEnabled(false)
            showFeedback("Completion notifications disabled.")
            return
        }

        let center = UNUserNotificationCenter.current()

        do {
            let currentSettings = await center.notificationSettings()

            if currentSettings.authorizationStatus == .denied {
                settings.setCompletionNotificationEnabled(false)
                notificationError =
                    "Notifications are disabled in iOS Settings."
                return
            }

            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            guard granted else {
                settings.setCompletionNotificationEnabled(false)
                notificationError =
                    "Notification permission was not granted."
                return
            }

            settings.setCompletionNotificationEnabled(true)
            showFeedback("Completion notifications enabled.")
        } catch {
            settings.setCompletionNotificationEnabled(false)
            notificationError =
                "Unable to request notification permission right now."
        }
    }
}

private struct DurationPicker: Identifiable {
    let id = UUID()
    let title: String
    let value: Int
    let range: ClosedRange<Int>
    let onSave: (Int) -> Void
}

private struct DurationPickerSheet: View {
    let title: String
    let range: ClosedRange<Int>
    let initialValue: Int
    let onSave: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var value: Int

    init(
        title: String,
        range: ClosedRange<Int>,
        initialValue: Int,
        onSave: @escaping (Int) -> Void
    ) {
        self.title = title
        self.range = range
        self.initialValue = initialValue
        self.onSave = onSave
        _value = State(initialValue: initialValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(title)
                    .font(.title3.weight(.semibold))

                Picker("Duration", selection: $value) {
                    ForEach(range, id: \.self) { minute in
                        Text("\(minute) min")
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .accessibilityIdentifier("settings.durationPicker")

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(value)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
