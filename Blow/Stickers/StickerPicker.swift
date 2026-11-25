import SwiftUI
import PhotosUI

/// Picks a sticker to place. "My photo" sits at the SAME level as the built-in
/// motifs — one flat list, no separate section — so uploading reads as just
/// another sticker choice. Uploaded images stay local; nothing is sent anywhere.
struct StickerPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem?
    let onPick: (StickerSource) -> Void

    private func row(tint: Color, symbol: String, title: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(tint).frame(width: 22, height: 22)
                Image(systemName: symbol).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
            }
            Text(title)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Add a sticker") {
                    // Tapping this row opens the system photo picker immediately —
                    // same row style and level as the motifs below.
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        row(tint: Color(hex: 0xE9C169), symbol: "photo", title: "My photos")
                    }

                    ForEach(StickerMotif.allCases) { motif in
                        Button {
                            onPick(.builtin(motif))
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Circle().fill(motif.tint).frame(width: 22, height: 22)
                                Text(motif.title)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add sticker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onChange(of: photoItem) { _, new in
                guard let new else { return }
                Task {
                    if let data = try? await new.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data),
                       let name = StickerStore.save(image: ui) {
                        await MainActor.run {
                            onPick(.custom(name))
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
