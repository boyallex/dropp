import AppKit
import Foundation

final class AppDelegate: NSObject, NSApplicationDelegate {

    var panelController: PanelController!
    var shakeDetector: ShakeDetector!

    /// Keeps a visible control in the menu bar because LSUIElement hides the Dock icon.
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        panelController = PanelController()

        setupStatusItem()

        shakeDetector = ShakeDetector { point in

            Task { @MainActor in

                self.panelController.show(
                    at: point
                )
            }
        }

        shakeDetector.start()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        if let button = item.button {
            // Template image follows light/dark menu bar automatically.
            let image = NSImage(
                systemSymbolName: "square.stack.3d.up.fill",
                accessibilityDescription: "DropShake"
            )
            image?.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()

        menu.addItem(
            NSMenuItem(
                title: "Show Panel",
                action: #selector(showPanel),
                keyEquivalent: ""
            )
        )

        menu.addItem(
            NSMenuItem(
                title: "Hide Panel",
                action: #selector(hidePanel),
                keyEquivalent: ""
            )
        )

        menu.addItem(.separator())

        menu.addItem(
            NSMenuItem(
                title: "Quit DropShake",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        item.menu = menu
        statusItem = item
    }

    @objc private func showPanel() {
        Task { @MainActor in
            panelController.show()
        }
    }

    @objc private func hidePanel() {
        Task { @MainActor in
            panelController.hide()
        }
    }
}
