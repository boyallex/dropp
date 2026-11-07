import AppKit
import Quartz

/// Owns Quick Look state for the current stack of files.
/// QLPreviewPanel keeps a weak-ish reference to dataSource/delegate, so this
/// object must stay alive while the preview is open (owned by PanelController).
final class QuickLookController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {

    private var urls: [URL] = []
    private var currentIndex = 0

    /// Opens Quick Look starting at a specific file in the given list.
    func preview(urls: [URL], startingAt index: Int) {
        guard !urls.isEmpty else {
            return
        }

        self.urls = urls
        self.currentIndex = max(0, min(index, urls.count - 1))
        openQuickLook()
    }

    @objc func openQuickLook() {
        guard let panel = QLPreviewPanel.shared() else {
            return
        }

        panel.dataSource = self
        panel.delegate = self
        panel.currentPreviewItemIndex = currentIndex
        panel.makeKeyAndOrderFront(nil)
    }

    // MARK: - QLPreviewPanelDataSource

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        urls.count
    }

    func previewPanel(
        _ panel: QLPreviewPanel!,
        previewItemAt index: Int
    ) -> (any QLPreviewItem)! {
        // NSURL already conforms to QLPreviewItem.
        urls[index] as NSURL
    }

    // MARK: - QLPreviewPanelDelegate

    func previewPanel(
        _ panel: QLPreviewPanel!,
        handle event: NSEvent!
    ) -> Bool {
        false
    }
}
