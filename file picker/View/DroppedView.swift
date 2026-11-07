import AppKit

/// Accepts file drops from other apps and can start a drag of stored files outward.
final class DropView: NSView, NSDraggingSource {

    var onDrop: (([URL]) -> Void)?
    var onDoubleClick: (() -> Void)?

    /// File URLs currently in the stack; used when the user drags out of this view.
    var dragOutURLs: [URL] = []

    private var mouseDownEvent: NSEvent?
    private var didStartDragging = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        registerForDraggedTypes([
            .fileURL
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Keep file drag-out here; the rest of the glass panel can move the window.
    override var mouseDownCanMoveWindow: Bool {
        false
    }

    // MARK: - Drag in

    override func draggingEntered(
        _ sender: any NSDraggingInfo
    ) -> NSDragOperation {
        // Ignore our own outbound drag so files are not re-added immediately.
        if sender.draggingSource as AnyObject? === self {
            return []
        }

        guard
            sender.draggingPasteboard
                .canReadObject(
                    forClasses: [NSURL.self],
                    options: [
                        .urlReadingFileURLsOnly: true
                    ]
                )
        else {
            return []
        }

        return .copy
    }

    override func prepareForDragOperation(
        _ sender: any NSDraggingInfo
    ) -> Bool {
        true
    }

    override func performDragOperation(
        _ sender: any NSDraggingInfo
    ) -> Bool {

        let urls =
            sender.draggingPasteboard.readObjects(
                forClasses: [NSURL.self],
                options: [
                    .urlReadingFileURLsOnly: true
                ]
            ) as? [URL] ?? []

        guard !urls.isEmpty else {
            return false
        }

        onDrop?(urls)

        return true
    }

    // MARK: - Drag out

    override func mouseDown(with event: NSEvent) {
        mouseDownEvent = event
        didStartDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard
            let mouseDownEvent,
            !dragOutURLs.isEmpty,
            !didStartDragging
        else {
            return
        }

        let start = mouseDownEvent.locationInWindow
        let current = event.locationInWindow
        let distance = hypot(current.x - start.x, current.y - start.y)

        // Small threshold avoids accidental drags on a plain click.
        guard distance > 5 else {
            return
        }

        didStartDragging = true

        let pointInView = convert(current, from: nil)
        let items = makeDraggingItems(
            for: dragOutURLs,
            at: pointInView
        )

        beginDraggingSession(
            with: items,
            event: mouseDownEvent,
            source: self
        )
    }

    override func mouseUp(with event: NSEvent) {
        // Double-click opens Quick Look; ignore if this press started a drag.
        if event.clickCount == 2,
            !didStartDragging,
            !dragOutURLs.isEmpty
        {
            onDoubleClick?()
        }

        mouseDownEvent = nil
        didStartDragging = false
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        // .copy lets Finder / other apps receive the files without moving them.
        .copy
    }

    private func makeDraggingItems(
        for urls: [URL],
        at point: NSPoint
    ) -> [NSDraggingItem] {
        urls.enumerated().map { index, url in
            // NSURL on the pasteboard is what other macOS apps expect for files.
            let item = NSDraggingItem(pasteboardWriter: url as NSURL)
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 64, height: 64)

            let offset = CGFloat(index) * 4
            let frame = NSRect(
                x: point.x - 32 + offset,
                y: point.y - 32 + offset,
                width: 64,
                height: 64
            )

            item.setDraggingFrame(frame, contents: icon)
            return item
        }
    }
}
