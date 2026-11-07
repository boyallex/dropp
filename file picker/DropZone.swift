import Foundation
import SwiftUI

struct DropZone: NSViewRepresentable {

    /// When non-empty, the user can drag these files out into other apps.
    var dragOutURLs: [URL] = []
    let onDrop: ([URL]) -> Void
    var onDoubleClick: (() -> Void)?

    func makeNSView(context: Context) -> DropView {
        let view = DropView()
        view.onDrop = onDrop
        view.dragOutURLs = dragOutURLs
        view.onDoubleClick = onDoubleClick
        return view
    }

    func updateNSView(
        _ nsView: DropView,
        context: Context
    ) {
        nsView.onDrop = onDrop
        nsView.dragOutURLs = dragOutURLs
        nsView.onDoubleClick = onDoubleClick
    }
}
