import AppKit
import SwiftUI

/// Shows either a real image thumbnail or the Finder-style file icon.
struct FilePreviewView: View {

    let file: DroppedFile

    /// Keep preview size close to a large Finder icon so the stack feels native.
    var size: CGFloat = 168

    var body: some View {
        Group {
            if file.isImage, let thumbnail = loadImageThumbnail() {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(nsImage: fileIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    // Padding scales with card size so tiny list icons stay readable.
                    .padding(size * 0.13)
            }
        }
        .frame(width: size, height: size)
        .background(cardBackground)
        .clipShape(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(
            color: .black.opacity(size > 60 ? 0.18 : 0.08),
            radius: size > 60 ? 8 : 2,
            x: 0,
            y: size > 60 ? 3 : 1
        )
    }

    private var cornerRadius: CGFloat {
        max(4, size * 0.08)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor))
    }

    /// NSWorkspace returns the same file icon that macOS uses in Finder.
    private var fileIcon: NSImage {
        let icon = NSWorkspace.shared.icon(forFile: file.url.path)
        icon.size = NSSize(width: size, height: size)
        return icon
    }

    /// Load a downscaled bitmap so large photos do not fill the whole panel.
    private func loadImageThumbnail() -> NSImage? {
        guard let sourceImage = NSImage(contentsOf: file.url) else {
            return nil
        }

        let targetSize = NSSize(width: size * 2, height: size * 2)
        let thumbnail = NSImage(size: targetSize)

        thumbnail.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high

        let sourceSize = sourceImage.size
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            thumbnail.unlockFocus()
            return nil
        }

        // Cover-style draw: fill the square, then the view clips to the card.
        let scale = max(
            targetSize.width / sourceSize.width,
            targetSize.height / sourceSize.height
        )
        let drawnSize = NSSize(
            width: sourceSize.width * scale,
            height: sourceSize.height * scale
        )
        let drawnRect = NSRect(
            x: (targetSize.width - drawnSize.width) / 2,
            y: (targetSize.height - drawnSize.height) / 2,
            width: drawnSize.width,
            height: drawnSize.height
        )

        sourceImage.draw(
            in: drawnRect,
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        thumbnail.unlockFocus()

        return thumbnail
    }
}
