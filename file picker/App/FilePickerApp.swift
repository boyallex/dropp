import SwiftUI

@main
struct FilePickerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
