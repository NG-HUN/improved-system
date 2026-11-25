import SwiftUI

/// List of saved birthday cakes. Load one into the editor, save the current
/// draft, set its date, and keep reminders in sync.
struct BirthdayLibraryView: View {
    @Binding var current: Birthday
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var items: [Birthday] = BirthdayLibrary.load()
    @State private var showPaywall = false
    @State private var showSaveDialog = false
    @State private var newPresetName = ""
    @State private var reminderEnabled = false
    @State private var daysBefore = 1
    @State private var reminderHour = 9

    private static let freeLimit = 3
    private static let vipLimit = 30
    private var presetLimit: Int { store.isVIP ? Self.vipLimit : Self.freeLimit }
    private var canSaveMore: Bool { items.count < presetLimit }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if canSaveMore {
                            newPresetName = current.presetTitle
                            showSaveDialog = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Label("Save current cake as new preset", systemImage: "square.and.arrow.down")
                    }
                    Text("Saved \(items.count)/\(presetLimit). Free: 3 cakes, VIP: up to 30 + reminders.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Each save adds a separate cake. Design a cake on the main screen, save it, then design another and save again.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section {
                    Text("How to keep several cakes")
                        .font(.subheadline.weight(.semibold))
                    Text("1. Design a cake on the main screen (style, candles, message, stickers).")
                    Text("2. Tap “Save current cake as new preset” above and give it a name — every save adds a new cake.")
                    Text("3. Design another and save it again. Tap any saved cake to preview it, change its date, or load it back into the editor.")
                } footer: {
                    Text("Saved cakes live here. Deleting one does not affect the cake you are editing now.")
                        .font(.caption)
                }

                Section("Birthday library") {
                    ForEach($items) { $item in
                        NavigationLink {
                            PresetDetail(item: $item, onSave: {
                                items = BirthdayLibrary.upsert(item, into: items)
                                syncReminders()
                            }, onLoad: {
                                current = item
                                dismiss()
                            })
                        } label: {
                            HStack(spacing: 12) {
                                // Live cake thumbnail for quick visual lookup.
                                CakePreview(birthday: item, flicker: false, showsStickers: false)
                                    .frame(width: 56, height: 56)
                                    .background(Color.black.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.presetTitle).font(.headline)
                                    Text("\(item.cake.title) · \(item.tiers) layer\(item.tiers == 1 ? "" : "s")")
                                        .font(.caption).foregroundStyle(.secondary)
                                    if let d = item.birthDate {
                                        Label(d.formatted(date: .long, time: .omitted), systemImage: "calendar")
                                            .font(.caption).foregroundStyle(.secondary)
                                    } else {
                                        Label("No date set", systemImage: "calendar.badge.plus")
                                            .font(.caption).foregroundStyle(.orange)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { idx in
                        let ids = idx.map { items[$0].id }
                        for id in ids { items = BirthdayLibrary.remove(id: id, from: items) }
                        syncReminders()
                    }
                }

                Section("Reminder settings") {
                    Toggle("Enable birthday reminders", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, _ in syncReminders() }
                    Picker("Remind", selection: $daysBefore) {
                        Text("Same day").tag(0)
                        Text("1 day before").tag(1)
                        Text("3 days before").tag(3)
                        Text("1 week before").tag(7)
                    }
                    .onChange(of: daysBefore) { _, _ in syncReminders() }
                    Picker("At", selection: $reminderHour) {
                        ForEach(6...22, id: \.self) { h in Text("\(h):00").tag(h) }
                    }
                    .onChange(of: reminderHour) { _, _ in syncReminders() }
                    if !store.isVIP {
                        Text("Reminders require VIP.").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Cake library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $showPaywall) { PaywallView().environment(store) }
            .alert("Save cake", isPresented: $showSaveDialog) {
                TextField("Cake name", text: $newPresetName)
                Button("Cancel", role: .cancel) {}
                Button("Save") { saveCurrentAsNewPreset() }
            } message: {
                Text("This adds a new cake to your library. The one you are editing stays unchanged.")
            }
        }
    }

    /// Always create a distinct preset: a fresh id means upsert appends instead of
    /// overwriting the single editable draft, so several cakes can be kept at once.
    private func saveCurrentAsNewPreset() {
        var snapshot = current
        snapshot.id = UUID()
        let base = newPresetName.trimmingCharacters(in: .whitespaces)
        snapshot.label = base.isEmpty ? snapshot.presetTitle : uniqueLabel(base)
        items = BirthdayLibrary.upsert(snapshot, into: items)
        newPresetName = ""
        syncReminders()
    }

    private func uniqueLabel(_ base: String) -> String {
        let taken = Set(items.map { $0.presetTitle })
        if !taken.contains(base) { return base }
        var n = 2
        while taken.contains("\(base) \(n)") { n += 1 }
        return "\(base) \(n)"
    }

    /// Edit the currently loaded preset's date via a detail sheet would be ideal;
    /// here we let each row carry its date when saved. Reminders are rebuilt from
    /// whatever dates the library holds.
    private func syncReminders() {
        Task {
            guard reminderEnabled && store.isVIP else {
                await ReminderManager.shared.cancelAll()
                return
            }
            if await ReminderManager.shared.requestAuthorization() {
                await ReminderManager.shared.reschedule(items, daysBefore: daysBefore, hour: reminderHour)
            }
        }
    }
/// Detail editor for one saved preset: a live preview, its name / date / age,
/// and shortcuts to save changes or load the cake back into the main editor.
private struct PresetDetail: View {
    @Binding var item: Birthday
    let onSave: () -> Void
    let onLoad: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                CakePreview(birthday: item, flicker: false, showsStickers: false)
                    .frame(height: 190)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [Color.black.opacity(0.30), Color.black.opacity(0.12)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            } header: {
                Text("Preview")
            }

            Section("Preset") {
                TextField("Name", text: $item.label)
                DatePicker("Birthday", selection: Binding(
                    get: { item.birthDate ?? Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1))! },
                    set: { item.birthDate = $0 }
                ), displayedComponents: .date)
                Toggle("Show age on cake", isOn: $item.showAge)
                Stepper("Age: \(item.age)", value: $item.age, in: 1...120)
            }

            Section("Cake") {
                Label("\(item.cake.title) · \(item.tiers) layer\(item.tiers == 1 ? "" : "s")", systemImage: "birthday.cake")
                if !item.cakeText.isEmpty {
                    Label("“\(item.cakeText)”", systemImage: "text.bubble")
                }
            }

            Section {
                Button("Save changes") { onSave() }
                Button("Load into editor") { onLoad() }
            }
        }
        .navigationTitle(item.presetTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

}
