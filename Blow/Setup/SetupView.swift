import SwiftUI

struct SetupView: View {
    @Binding var birthday: Birthday
    let onStart: (Birthday) -> Void

    @Environment(StoreManager.self) private var store
    @State private var showPaywall = false
    @FocusState private var focused: Bool
    /// A separate player just for auditioning the tune in setup; the ceremony owns its own.
    @State private var previewPlayer = SongPlayer()
    @State private var previewing = false
    @State private var showStickerEditor = false
    @State private var stickerSelection: UUID?
    @State private var showLibrary = false

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 700
            Group {
                if wide {
                    // On a big screen the cake has a permanent home on the left.
                    HStack(spacing: 0) {
                        preview(compact: false)
                            .frame(width: geo.size.width * 0.48)
                        ScrollView { form.padding(.vertical, 40) }
                            .frame(width: geo.size.width * 0.52)
                    }
                } else {
                    // On a phone the cake is pinned above the form: only the options
                    // scroll, so the preview stays visible and answers every change live.
                    VStack(spacing: 0) {
                        preview(compact: true)
                            .frame(height: min(geo.size.height * 0.52, 440))
                        Divider().overlay(Theme.hairline)
                        ScrollView { form.padding(.top, 24) }
                            .scrollDismissesKeyboard(.interactively)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .background(Theme.night.ignoresSafeArea())
        .sheet(isPresented: $showPaywall) { PaywallView().environment(store) }
        .sheet(isPresented: $showStickerEditor) {
            StickerEditor(birthday: birthday, stickers: $birthday.stickers)
        }
        .sheet(isPresented: $showLibrary) {
            BirthdayLibraryView(current: $birthday)
        }
        .onChange(of: birthday) { _, new in new.save() }
        .onChange(of: birthday.cake) { _, _ in
            if birthday.cakeText.count > birthday.cakeTextLimit {
                birthday.cakeText = String(birthday.cakeText.prefix(birthday.cakeTextLimit))
            }
        }
        .task {
            #if DEBUG
            if UserDefaults.standard.string(forKey: "blow.editor") == "1" { showStickerEditor = true }
            if UserDefaults.standard.string(forKey: "blow.select") == "1" { stickerSelection = birthday.stickers.first?.id }
            if UserDefaults.standard.string(forKey: "blow.library") == "1" { showLibrary = true }
            #endif
            await previewPlayer.prepare(rounds: 1, choice: birthday.song)
        }
        .onDisappear { previewPlayer.stop() }
    }

    // MARK: preview

    private func preview(compact: Bool) -> some View {
        VStack(spacing: compact ? 0 : 4) {
            if compact {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("Blow")
                        .font(Theme.serif(24, weight: .medium))
                        .foregroundStyle(Theme.cream)
                    Text("a birthday, by candlelight")
                        .font(Theme.serif(12).italic())
                        .foregroundStyle(Theme.muted)
                }
                .padding(.top, 12)
            } else {
                Text("Blow")
                    .font(Theme.serif(40, weight: .medium))
                    .foregroundStyle(Theme.cream)
                    .padding(.top, 24)
                Text("a birthday, by candlelight")
                    .font(Theme.serif(15).italic())
                    .foregroundStyle(Theme.muted)
            }
            // Stickers are arranged right on the preview: tap one to select it,
            // then drag it or use the two on-canvas handles to scale and rotate.
            InteractiveStickerCanvas(stickers: $birthday.stickers, selectedID: $stickerSelection) {
                CakePreview(birthday: birthday, showsStickers: false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: form

    private var form: some View {
        VStack(alignment: .leading, spacing: 28) {
            #if DEBUG
            // One tap unlocks every Pro item so the whole collection can be reviewed in Xcode.
            HStack(spacing: 10) {
                Image(systemName: store.isPro ? "checkmark.seal.fill" : "seal")
                    .foregroundStyle(store.isPro ? Theme.glow : Theme.muted)
                Text(store.isPro ? "Pro preview is ON" : "Pro preview (test)")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button(store.isPro ? "Turn off" : "Unlock all") {
                    if store.isPro { store.debugLock() } else { store.debugUnlock() }
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().stroke(Theme.paper.opacity(0.5)))
            }
            .foregroundStyle(Theme.cream)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
            #endif

            section("Who's celebrating") {
                TextField("", text: $birthday.name, prompt: Text("Name").foregroundColor(Theme.muted.opacity(0.6)))
                    .font(Theme.serif(26))
                    .foregroundStyle(Theme.cream)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($focused)
                    .padding(.vertical, 6)
                    .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 1) }
                TextField("", text: $birthday.recipient,
                          prompt: Text("For (leave blank to use the name above)").foregroundColor(Theme.muted.opacity(0.45)))
                    .font(Theme.serif(16).italic())
                    .foregroundStyle(Theme.cream.opacity(0.85))
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($focused)
                    .padding(.top, 4)
                    .padding(.vertical, 6)
                    .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 1) }
            }

            section("Turning") {
                if birthday.cake.fixedCandleDigits != nil {
                    HStack(spacing: 10) {
                        Image(systemName: "18.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.glow.opacity(0.85))
                        Text("This cake carries a fixed 18 candle — no age to set.")
                            .font(Theme.serif(15).italic())
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.vertical, 8)
                } else {
                    HStack(spacing: 18) {
                        roundButton("minus") { birthday.age = max(0, birthday.age - 1) }
                        Text("\(birthday.age)")
                            .font(Theme.serif(44, weight: .medium))
                            .monospacedDigit()
                            .foregroundStyle(Theme.cream)
                            .frame(minWidth: 80)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: birthday.age)
                        roundButton("plus") { birthday.age = min(120, birthday.age + 1) }
                        Spacer()
                    }
                    Toggle("Show age on the cake", isOn: $birthday.showAge)
                    Toggle("Number candles", isOn: Binding(
                        get: { birthday.usesNumberCandles },
                        set: { birthday.numberCandles = $0 }))
                        .disabled(!birthday.showAge)
                }
            }
            .tint(Theme.accent)

            section("Written on the cake") {
                TextField("", text: $birthday.cakeText, prompt: Text("Happy Birthday").foregroundColor(Theme.muted.opacity(0.6)))
                    .font(Theme.serif(20).italic())
                    .foregroundStyle(Theme.cream)
                    .focused($focused)
                    .padding(.vertical, 6)
                    .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 1) }
                    .onChange(of: birthday.cakeText) { _, v in
                        let limit = birthday.cakeTextLimit
                        if v.count > limit { birthday.cakeText = String(v.prefix(limit)) }
                    }
                HStack {
                    Text("Kept short so it pipes neatly on the \(birthday.cake.title) cake.")
                        .font(Theme.serif(12).italic())
                        .foregroundStyle(Theme.muted.opacity(0.6))
                    Spacer(minLength: 4)
                    Text("\(birthday.cakeText.count)/\(birthday.cakeTextLimit)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.muted.opacity(0.6))
                }

                // The message can be customised beyond the cake's built-in look.
                // Sliders start from the style's own defaults via the `??` fallbacks.
                let spec = birthday.cake.lettering
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Height on cake", systemImage: "arrow.up.arrow.down")
                        Spacer()
                        Text("\(Int((birthday.textEdit.v ?? spec.v) * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.muted)
                    }
                    Slider(value: Binding(
                        get: { birthday.textEdit.v ?? spec.v },
                        set: { birthday.textEdit.v = $0 }), in: 0.30...0.92)
                    .tint(Theme.accent)

                    HStack {
                        Label("Letter size", systemImage: "textformat.size")
                        Spacer()
                        Text("\(Int((birthday.textEdit.size ?? spec.size) * 1000))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.muted)
                    }
                    Slider(value: Binding(
                        get: { birthday.textEdit.size ?? spec.size },
                        set: { birthday.textEdit.size = $0 }), in: 0.035...0.14)
                    .tint(Theme.accent)

                    HStack {
                        Label("Icing colour", systemImage: "paintpalette")
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { Color(hex: birthday.textEdit.colorHex ?? spec.colorHex) },
                            set: { birthday.textEdit.colorHex = $0.rgbHex }))
                            .labelsHidden()
                            .frame(width: 44, height: 30)
                    }

                    if !birthday.textEdit.isEmpty {
                        Button {
                            birthday.textEdit = TextEdit()
                        } label: {
                            Label("Reset to cake default", systemImage: "arrow.counterclockwise")
                                .font(.caption.weight(.medium))
                        }
                        .tint(Theme.accent)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(Theme.cream.opacity(0.85))
                .padding(.top, 4)
            }

            section("Cake") {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(CakeStyle.allCases) { cake in
                                let locked = cake.isPro && !store.isPro
                                Button {
                                    if locked { showPaywall = true; return }
                                    // a cake arrives with the candles it was drawn with
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        birthday.cake = cake
                                        birthday.candle = cake.candle
                                    }
                                } label: {
                                    CakeCard(cake: cake, selected: cake == birthday.cake, locked: locked)
                                }
                                .buttonStyle(.plain)
                                .id(cake)
                            }
                        }
                        .padding(.horizontal, 28)
                    }
                    .padding(.horizontal, -28)
                    .onAppear { proxy.scrollTo(birthday.cake, anchor: .center) }
                }
            }

            section("Cake tiers") {
                HStack(spacing: 10) {
                    ForEach(1...3, id: \.self) { n in
                        let on = birthday.tiers == n
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) { birthday.tiers = n }
                        } label: {
                            VStack(spacing: 4) {
                                tierGlyph(n)
                                    .frame(width: 30, height: 26)
                                Text(n == 1 ? "One" : (n == 2 ? "Two" : "Three"))
                                    .font(.subheadline.weight(on ? .semibold : .regular))
                            }
                            .frame(width: 76, height: 62)
                            .background(Capsule().fill(on ? Color.white.opacity(0.09) : Color.white.opacity(0.05)))
                            .overlay(Capsule().stroke(on ? Theme.paper.opacity(0.7) : Theme.hairline))
                            .foregroundStyle(on ? Theme.cream : Theme.cream.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            section("Candles") {
                chips(CandleStyle.allCases, selected: birthday.candle, title: \.title, isPro: \.isPro,
                      swatch: { AnyShapeStyle(LinearGradient(colors: $0.wax, startPoint: .top, endPoint: .bottom)) }) {
                    birthday.candle = $0
                }
            }

            section("Finishing touch") {
                // Berries is retired (drew a stray ring of red fruit on every cake);
                // keep it selectable only if already saved, never offer it anew.
                let toppers = CakeTopper.allCases.filter { $0 != .berries }
                chips(toppers, selected: birthday.topper, title: \.title, isPro: \.isPro, swatch: nil) {
                    birthday.topper = $0
                }
            }

            section("The song") {
                // Four genuinely different tunes; tapping one re-renders the preview.
                chips(SongChoice.allCases, selected: birthday.song, title: \.title,
                      isPro: \.isProSong, swatch: nil) {
                    birthday.song = $0
                    previewPlayer.preparePreview(rounds: 1, choice: $0)
                }
                Text(birthday.song.subtitle)
                    .font(Theme.serif(12).italic())
                    .foregroundStyle(Theme.muted.opacity(0.6))
                    .padding(.top, -2)
                HStack(spacing: 14) {
                    Button {
                        previewPlayer.preview()
                        previewing = true
                        Task {
                            try? await Task.sleep(for: .seconds(6.8))
                            previewing = false
                        }
                    } label: {
                        Label(previewing ? "Playing…" : "Hear the tune",
                              systemImage: previewing ? "waveform" : "play.circle")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(Capsule().stroke(Theme.paper.opacity(0.5)))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.cream)
                    Text("a little music-box preview")
                        .font(Theme.serif(12).italic())
                        .foregroundStyle(Theme.muted.opacity(0.6))
                    Spacer()
                }
                // Lyrics are a separate axis: the tune stays the same, words change.
                HStack {
                    Text("Lyric language")
                        .font(Theme.serif(12))
                        .foregroundStyle(Theme.muted.opacity(0.8))
                    Spacer()
                }
                chips(SongLanguage.allCases, selected: birthday.language, title: \.title, isPro: \.isPro, swatch: nil) {
                    birthday.language = $0
                }
                HStack {
                    Text("Sing it")
                    Spacer()
                    Picker("Rounds", selection: $birthday.rounds) {
                        Text("once").tag(1)
                        Text("twice").tag(2)
                        Text("three times").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 260)
                }
            }

            section("Atmosphere stickers") {
                Text("Floating decorations around the cake")
                    .font(Theme.serif(12).italic())
                    .foregroundStyle(Theme.muted.opacity(0.6))
                // Add built-in motifs; each new one lands at a free ring position.
                chips(StickerMotif.allCases, selected: .balloon, title: \.title,
                      isPro: \.notPro, swatch: { AnyShapeStyle($0.tint) }) { motif in
                    addSticker(motif)
                }
                Button {
                    showStickerEditor = true
                } label: {
                    Label("Arrange & upload", systemImage: "hand.draw")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(Capsule().stroke(Theme.paper.opacity(0.5)))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.cream)
                if !birthday.stickers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(birthday.stickers) { s in
                                stickerChip(s)
                            }
                        }
                    }
                    Button {
                        removeAllStickers()
                    } label: {
                        Label("Clear all", systemImage: "trash")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                } else {
                    Text("Tap a motif above to place it around the cake.")
                        .font(Theme.serif(12))
                        .foregroundStyle(Theme.muted.opacity(0.6))
                }
            }

            Button {
                showLibrary = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                    Text("Cake library")
                }
                .font(Theme.serif(16, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Capsule().stroke(Theme.accent.opacity(0.75)))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.cream)

            Button {
                focused = false
                onStart(birthday)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                    Text("Light the candles")
                }
                .font(Theme.serif(20, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Capsule().fill(Theme.paper))
                .foregroundStyle(Theme.ink)
                .shadow(color: Theme.accent.opacity(0.28), radius: 26)
            }
            .padding(.top, 8)

            Text("Turn the lights down. Stand the phone on the table.")
                .font(Theme.serif(14).italic())
                .foregroundStyle(Theme.muted.opacity(0.7))
                .frame(maxWidth: .infinity)
        }
        .foregroundStyle(Theme.cream.opacity(0.85))
        .padding(.horizontal, 28)
        .padding(.bottom, 40)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.6)
                .foregroundStyle(Theme.muted.opacity(0.7))
            content()
        }
    }

    private func tierGlyph(_ n: Int) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let tierH = h / CGFloat(n + 1)
            for i in 0..<n {
                let level = n - 1 - i
                let tw = w * (0.46 + CGFloat(level) * 0.27)
                let ty = h - CGFloat(i + 1) * tierH - 1
                let r = CGRect(x: (w - tw) / 2, y: ty, width: tw, height: tierH)
                var p = Path()
                p.addRect(CGRect(x: r.minX, y: r.minY, width: tw, height: tierH * 0.7))
                p.addEllipse(in: CGRect(x: r.minX, y: r.midY - tierH * 0.30, width: tw, height: tierH * 0.60))
                ctx.fill(p, with: .color(Theme.cream.opacity(0.55)))
                ctx.fill(Path(ellipseIn: CGRect(x: r.minX, y: ty - tierH * 0.18, width: tw, height: tierH * 0.42)),
                         with: .color(Theme.cream.opacity(0.75)))
            }
        }
    }

    private func roundButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.07)))
        }
        .foregroundStyle(Theme.cream)
        .buttonRepeatBehavior(.enabled)
    }

    /// Place a new motif at the next free ring slot around the cake.
    private func addSticker(_ motif: StickerMotif) {
        let slots: [(CGFloat, CGFloat, Double)] = [
            (0.14, 0.30, -8), (0.86, 0.26, 7), (0.24, 0.15, 12),
            (0.76, 0.45, -10), (0.10, 0.55, 25), (0.90, 0.58, -18),
            (0.34, 0.12, 5), (0.66, 0.12, -5), (0.18, 0.68, 15), (0.82, 0.70, -15),
        ]
        let used = birthday.stickers.count
        let s = slots[used % slots.count]
        birthday.stickers.append(StickerPlacement(
            source: .builtin(motif), x: s.0, y: s.1, scale: 0.09, rotation: s.2))
    }

    /// Deleting a custom photo also removes its local PNG so files don't pile up.
    private func removeSticker(_ s: StickerPlacement) {
        if case .custom(let file) = s.source { StickerStore.remove(named: file) }
        birthday.stickers.removeAll { $0.id == s.id }
    }

    private func removeAllStickers() {
        for s in birthday.stickers {
            if case .custom(let file) = s.source { StickerStore.remove(named: file) }
        }
        birthday.stickers.removeAll()
    }

    private func stickerChip(_ s: StickerPlacement) -> some View {
        let label: String = {
            switch s.source {
            case .builtin(let m): return m.title
            case .custom: return "My photo"
            }
        }()
        let colour: Color = {
            switch s.source {
            case .builtin(let m): return m.tint
            case .custom: return Color(hex: 0xE9C169)
            }
        }()
        return HStack(spacing: 6) {
            Circle().fill(colour).frame(width: 12, height: 12)
            Text(label).font(.caption)
            Button {
                removeSticker(s)
            } label: {
                Image(systemName: "xmark.circle.fill").font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.06)))
    }

    private func chips<Item: Identifiable & Equatable>(
        _ items: [Item], selected: Item,
        title: KeyPath<Item, String>, isPro: KeyPath<Item, Bool>,
        swatch: ((Item) -> AnyShapeStyle)?,
        select: @escaping (Item) -> Void
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(items) { item in
                    let locked = item[keyPath: isPro] && !store.isPro
                    let on = item == selected
                    Button {
                        if locked { showPaywall = true } else { select(item) }
                    } label: {
                        HStack(spacing: 8) {
                            if let swatch {
                                Circle().fill(swatch(item)).frame(width: 16, height: 16)
                            }
                            Text(item[keyPath: title])
                            if locked {
                                Image(systemName: "lock.fill").font(.system(size: 10)).opacity(0.6)
                            }
                        }
                        .font(.subheadline.weight(on ? .semibold : .regular))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(
                            Capsule().fill(on ? Theme.accent.opacity(0.18) : Color.white.opacity(0.05))
                        )
                        .overlay(Capsule().stroke(on ? Theme.accent : Theme.hairline))
                        .foregroundStyle(on ? Theme.cream : Theme.cream.opacity(0.7))
                    }
                }
            }
        }
    }
}

/// One cake in the picker: a small still life, its name, and a line about its mood.
struct CakeCard: View {
    let cake: CakeStyle
    let selected: Bool
    var locked: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            ZStack(alignment: .topTrailing) {
                CakePreview(birthday: Birthday(showAge: false, cakeText: "", cake: cake, candle: cake.candle), flicker: false)
                    .frame(width: 128, height: 150)
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.cream)
                        .padding(8)
                        .background(Circle().fill(.black.opacity(0.5)))
                        .padding(6)
                }
            }
            Text(cake.title)
                .font(Theme.serif(15, weight: .medium))
                .foregroundStyle(Theme.cream)
            Text(cake.mood)
                .font(Theme.serif(11).italic())
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 12)
        .frame(width: 148)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(selected ? Color.white.opacity(0.07) : Color.white.opacity(0.03)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(selected ? Theme.paper.opacity(0.7) : Theme.hairline, lineWidth: selected ? 1.5 : 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(cake.title), \(cake.mood)\(locked ? ", locked" : "")")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}
