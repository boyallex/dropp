import Combine
import Foundation

@MainActor
final class DropStore: ObservableObject {

    @Published private(set) var files: [DroppedFile] = []

    func add(urls: [URL]) {
        let newFiles = urls.map {
            DroppedFile(url: $0)
        }

        // Same absolute path should not appear twice in the stack.
        let existingURLs = Set(files.map(\.url))

        let uniqueFiles = newFiles.filter {
            !existingURLs.contains($0.url)
        }

        files.append(contentsOf: uniqueFiles)
    }

    func remove(_ file: DroppedFile) {
        files.removeAll {
            $0.id == file.id
        }
    }

    func clear() {
        files.removeAll()
    }
}
