import Foundation
import UniformTypeIdentifiers

struct DroppedFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL

    var name: String {
        url.lastPathComponent
    }

    var size: Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    /// Prefer UTType over a hard-coded extension list so HEIC/WebP/etc. stay correct.
    var isImage: Bool {
        if let type = UTType(filenameExtension: url.pathExtension),
           type.conforms(to: .image)
        {
            return true
        }

        // Fallback when the extension is missing or unknown.
        if let typeIdentifier = try? url.resourceValues(
            forKeys: [.contentTypeKey]
        ).contentType {
            return typeIdentifier.conforms(to: .image)
        }

        return false
    }
}
