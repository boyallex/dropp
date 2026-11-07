import AppKit
import SwiftUI

@MainActor
final class PanelController: NSObject {

    private var panel: NSPanel?
    private let store = DropStore()
    private let quickLook = QuickLookController()

    /// After the first show we keep the user's panel position (no snap-to-cursor).
    private var didPlacePanel = false

    /// Show without forcing a new cursor-based position (status menu / reopen).
    func show() {
        show(at: NSEvent.mouseLocation)
    }

    func show(at point: NSPoint) {

        if panel == nil {
            createPanel()
        }

        guard let panel else {
            return
        }

        if !didPlacePanel {
            panel.setFrameOrigin(
                NSPoint(
                    x: point.x - panel.frame.width / 2,
                    y: point.y - panel.frame.height / 2
                )
            )
            didPlacePanel = true
        }

        // Re-assert level/behavior in case macOS reset them after space changes.
        applyAlwaysOnTopBehavior(to: panel)
        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let rootView = DropPanelView(
            store: store,
            quickLook: quickLook
        )

        let hostingView = NSHostingView(rootView: rootView)

        // Full-window Liquid Glass chrome; SwiftUI sits inside as content.
        let glassView = NSGlassEffectView()
        glassView.cornerRadius = 22
        glassView.style = .regular
        glassView.contentView = hostingView

        let panel = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: 200,
                height: 220
            ),
            styleMask: [
                .titled,
                .closable,
                .fullSizeContentView,
                .nonactivatingPanel,
            ],
            backing: .buffered,
            defer: false
        )

        panel.contentView = glassView

        // Transparent window so the glass can sample the desktop.
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true

        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true

        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        // Drag the panel by the glass background; DropView opts out separately.
        panel.isMovableByWindowBackground = true

        panel.standardWindowButton(.closeButton)?.target = self
        panel.standardWindowButton(.closeButton)?.action = #selector(
            closePanelButtonClicked
        )

        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        applyAlwaysOnTopBehavior(to: panel)

        self.panel = panel

        NotificationCenter.default.addObserver(
            forName: .dropShakeClosePanel,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                self?.hide()
            }
        }
    }

    @objc private func closePanelButtonClicked() {
        hide()
        store.clear()
        print("panel closed")
    }

    /// Keep the panel above normal windows on every Space, including full screen.
    private func applyAlwaysOnTopBehavior(to panel: NSPanel) {
        // Higher than .floating so regular app windows stay underneath.
        panel.level = .statusBar

        panel.collectionBehavior = [
            // Visible on all desktops / Mission Control spaces.
            .canJoinAllSpaces,
            // Stays put when the user switches spaces.
            .stationary,
            // Allowed as an auxiliary window over full-screen apps.
            .fullScreenAuxiliary,
        ]
    }
}
