import SwiftUI

/// A full-screen editor for arranging ambient stickers on the real cake.
/// Everything happens on the canvas: tap a sticker, drag it, drag the corner
/// handle to scale, drag the top handle to rotate; pinch and twist also work.
/// The sliders below are only for fine tuning a selected sticker.
struct StickerEditor: View {
    let birthday: Birthday
    @Binding var stickers: [StickerPlacement]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: UUID?
    @State private var showPicker = false
    @State private var showPaywall = false
    @Environment(StoreManager.self) private var store

    /// The cake without its stored stickers — the interactive canvas draws them.
    private var cakeWithoutStickers: Birthday {
        var b = birthday
        b.stickers = []
        return b
    }

    private var selected: StickerPlacement? {
        get { stickers.first { $0.id == selectedID } }
        set { if let n = newValue, let i = stickers.firstIndex(where: { $0.id == n.id }) { stickers[i] = n } }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                InteractiveStickerCanvas(stickers: $stickers, selectedID: $selectedID) {
                    CakePreview(birthday: cakeWithoutStickers, flicker: false, showsStickers: false)
                }
                .frame(height: 360)
                .background(Color.black.opacity(0.35))

                if let s = selected {
                    VStack(spacing: 12) {
                        label(for: s.source)
                        HStack {
                            Text("Fine size"); Spacer()
                            Slider(value: bindingScale(s), in: 0.035...0.35)
                        }
                        HStack {
                            Text("Fine rotation"); Spacer()
                            Slider(value: bindingRotation(s), in: -180...180)
                        }
                        Button(role: .destructive) {
                            removeSticker(s)
                        } label: {
                            Label("Remove sticker", systemImage: "trash")
                        }
                    }
                    .padding()
                } else {
                    Text("Tap a sticker, then drag it — corner handle scales, top handle rotates, the red × deletes. Pinch or twist to adjust both.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Spacer()
                Button { showPicker = true } label: {
                    Label("Add sticker", systemImage: "plus.circle")
                }
                .padding()
            }
            .navigationTitle("Arrange stickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $showPicker) {
                StickerPicker { source in
                    let s = StickerPlacement(source: source, x: 0.5, y: 0.22, scale: 0.1)
                    stickers.append(s)
                    selectedID = s.id
                    showPicker = false
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView().environment(store) }
            #if DEBUG
            .onAppear {
                if UserDefaults.standard.string(forKey: "blow.select") == "1" { selectedID = stickers.first?.id }
                if UserDefaults.standard.string(forKey: "blow.picker") == "1" { showPicker = true }
            }
            #endif
        }
    }

    /// Remove a placement and, if it was a custom photo, its local file too.
    /// Shared by the bottom "Remove sticker" button and the on-canvas red × lives
    /// in InteractiveStickerCanvas, which calls the same helper via `remove`.
    private func removeSticker(_ s: StickerPlacement) {
        if case .custom(let file) = s.source { StickerStore.remove(named: file) }
        stickers.removeAll { $0.id == s.id }
        selectedID = nil
    }

    private func label(for source: StickerSource) -> some View {
        let text: String
        switch source {
        case .builtin(let m): text = m.title
        case .custom: text = "My photo"
        }
        return Text(text).font(.headline)
    }

    private func bindingScale(_ s: StickerPlacement) -> Binding<CGFloat> {
        Binding(get: { s.scale }, set: { v in
            if let i = stickers.firstIndex(where: { $0.id == s.id }) { stickers[i].scale = v }
        })
    }

    private func bindingRotation(_ s: StickerPlacement) -> Binding<Double> {
        Binding(get: { s.rotation }, set: { v in
            if let i = stickers.firstIndex(where: { $0.id == s.id }) { stickers[i].rotation = v }
        })
    }
}
