import SwiftUI
import AVFoundation

@main
struct BlowApp: App {
    @UIApplicationDelegateAdaptor(NotificationDelegate.self) private var appDelegate
    @State private var store = StoreManager()

    init() {
        #if DEBUG
        Self.applyDebugArguments()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            FoldSimHost {
                RootView()
                    .environment(store)
                    .preferredColorScheme(.dark)
                    .tint(Theme.accent)
            }
        }
    }

    #if DEBUG
    /// Mirror `-blow.cake noir`-style launch arguments into UserDefaults so the
    /// screenshot hooks in Birthday/CeremonyModel can read them. Handy in Xcode: add
    /// the same flags under Scheme → Run → Arguments to jump to any cake or scene.
    private static func applyDebugArguments() {
        let args = ProcessInfo.processInfo.arguments
        let defaults = UserDefaults.standard
        var supplied: [String] = []
        var i = 0
        while i < args.count - 1 {
            let key = args[i]
            if key.hasPrefix("-blow.") {
                let name = String(key.dropFirst())
                defaults.set(args[i + 1], forKey: name)
                supplied.append(name)
                i += 2
            } else {
                i += 1
            }
        }
        // Clear hooks from a previous launch so a fresh run starts clean.
        for key in ["blow.cake", "blow.candle", "blow.tiers", "blow.song", "blow.stickers", "blow.celebrate",
                    "blow.celebrateAt", "blow.celebrateFreeze", "blow.showCard", "blow.phase",
                    "blow.elapsed", "blow.mode", "blow.editor", "blow.select",
                    "blow.age", "blow.numberCandles", "blow.textV", "blow.textSize",
                    "blow.textColor", "blow.heart", "blow.library", "blow.picker"] where !supplied.contains(key) {
            defaults.removeObject(forKey: key)
        }
    }
    #endif
}

struct RootView: View {
    @Environment(StoreManager.self) private var store
    @State private var birthday = Birthday.load()
    /// Snapshot taken when the ritual starts. Closures here that read `birthday` directly
    /// can see a stale value, because this body never reads it otherwise.
    @State private var ceremony: Ceremony?
    @State private var cardTarget: Birthday?
    #if DEBUG
    @State private var debugAutoCelebrate: Bool = UserDefaults.standard.string(forKey: "blow.celebrate") == "1"
        || UserDefaults.standard.string(forKey: "blow.phase") != nil
    #endif

    struct Ceremony: Identifiable {
        let id = UUID()
        let birthday: Birthday
    }

    var body: some View {
        // Presented in place rather than as a full-screen cover, so the ritual lives in the
        // same window as everything else — and follows it when the window resizes on a fold.
        ZStack {
            if ceremony == nil {
                SetupView(birthday: $birthday) { snapshot in
                    snapshot.save()
                    Task {
                        // ask for the mic now, so no permission alert interrupts the ritual later
                        _ = await AVAudioApplication.requestRecordPermission()
                        ceremony = Ceremony(birthday: snapshot)
                    }
                }
                .transition(.opacity)
            }
            if let ceremony {
                CeremonyView(birthday: ceremony.birthday) { self.ceremony = nil }
                    .persistentSystemOverlays(.hidden)
                    .statusBarHidden()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: ceremony?.id)
        .sheet(item: $cardTarget) { target in
            MemoryCardSheet(birthday: target).environment(store)
        }
        .onAppear { checkNotificationLaunch() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkNotificationLaunch()
            ReminderManager.shared.clearBadge()
        }
        #if DEBUG
        .onAppear {
            if debugAutoCelebrate, ceremony == nil {
                ceremony = Ceremony(birthday: birthday)
            }
        }
        #endif
    }

    /// A reminder / shared-card tap stores the target preset UUID.
    ///
    /// On a folding phone the card arrives as a wrapped gift: we enter the ritual
    /// at its boxed stage, so the small cover screen shows the bow, and unfolding
    /// to the large screen opens the box — the cake appears and the candles light.
    /// On any screen already large (e.g. an open fold or a tablet) the ceremony
    /// opens itself on appear, so nobody is left staring at a closed box.
    private func checkNotificationLaunch() {
        guard let uuid = UserDefaults.standard.string(forKey: NotificationDelegate.launchKey),
              let id = UUID(uuidString: uuid) else { return }
        UserDefaults.standard.removeObject(forKey: NotificationDelegate.launchKey)
        if let preset = BirthdayLibrary.load().first(where: { $0.id == id }) {
            // Present the boxed ceremony directly so the bow shows immediately;
            // unfolding drives the rest. The blow stage falls back to swipe if
            // microphone access was never granted.
            ceremony = Ceremony(birthday: preset)
        }
    }
}

extension EnvironmentValues {
    /// True on a phone known to fold. iOS has no public API for this yet, so only the
    /// debug fold simulator sets it; the ritual still reacts to the screen resizing either way.
    @Entry var canFold = false
}

/// Wraps the app in the debug fold simulator when launched with `-foldSim`.
struct FoldSimHost<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-foldSim") {
            FoldSimulator(content: content)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

#if DEBUG
/// Stand-in for the folding iPhone, which has no simulator yet. Run on a large iPad simulator:
/// the app lives in a phone-sized window that can be folded, opened, or stood up as a tabletop,
/// so the posture logic sees the same size changes it would on the real thing.
/// Sizes follow the rumoured 5.5" cover and 7.8" inner panels, in points.
struct FoldSimulator<Content: View>: View {
    let content: Content

    enum Mode: String, CaseIterable, Identifiable {
        case folded = "Folded", book = "Open", tabletop = "Tabletop"
        var id: String { rawValue }

        var size: CGSize {
            switch self {
            case .folded: CGSize(width: 474, height: 696)
            case .book: CGSize(width: 904, height: 640)
            case .tabletop: CGSize(width: 640, height: 904)
            }
        }
    }

    @State private var mode: Mode = {
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "blow.mode"), let m = Mode(rawValue: raw) { return m }
        #endif
        return .folded
    }()

    var body: some View {
        GeometryReader { geo in
            let size = mode.size
            let room = CGSize(width: geo.size.width - 32, height: geo.size.height - 90)
            let scale = min(1, room.width / size.width, room.height / size.height)
            VStack(spacing: 20) {
                content
                    .environment(\.canFold, true)
                    .frame(width: size.width, height: size.height)
                    .overlay { crease(for: mode, size: size) }
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).stroke(.white.opacity(0.18), lineWidth: 2))
                    .scaleEffect(scale)
                    .frame(width: size.width * scale, height: size.height * scale)

                Picker("Posture", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 360)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(white: 0.16).ignoresSafeArea())
    }

    /// A faint dashed line where the hinge would be.
    @ViewBuilder
    private func crease(for mode: Mode, size: CGSize) -> some View {
        if mode != .folded {
            Path { p in
                if mode == .book {
                    p.move(to: CGPoint(x: size.width / 2, y: 0)); p.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                } else {
                    p.move(to: CGPoint(x: 0, y: size.height / 2)); p.addLine(to: CGPoint(x: size.width, y: size.height / 2))
                }
            }
            .stroke(.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
            .allowsHitTesting(false)
        }
    }
}
#endif
