import SwiftUI
import UniformTypeIdentifiers

//#Preview {
//    DropPanelView(store: DropStore(), quickLook: QuickLookController())
//}

struct DropPanelView: View {

    @ObservedObject var store: DropStore
    let quickLook: QuickLookController

    /// false = visual stack, true = flat file list in the same area.
    @State private var showsFileList = false

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(fileCountLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 2)
            }

            mainContent

            if !store.files.isEmpty {

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showsFileList.toggle()
                    }
                } label: {
                    Label(
                        showsFileList ? "Show stack" : "Show files",
                        systemImage: showsFileList
                            ? "square.stack.3d.up"
                            : "list.bullet"
                    )
                    .font(.caption)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .foregroundStyle(.secondary)

            }

        }
        .padding(8)
        .onChange(of: store.files.isEmpty) { _, isEmpty in
            if isEmpty {
                showsFileList = false
            }
        }
        .padding(.bottom, 4)
        
    }

    private var mainContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    Color.secondary.opacity(0.35),
                    style: StrokeStyle(lineWidth: 1, dash: [5])
                )

            if store.files.isEmpty {
                stackDropZone
                emptyState
                    .allowsHitTesting(false)
            } else if showsFileList {
                fileList
            } else {
                stackDropZone
                FileStackView(files: store.files)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: 170, height: 190)
    }

    /// DropZone stays hit-testable so drag-in and drag-out both work in stack mode.
    private var stackDropZone: some View {
        DropZone(
            dragOutURLs: store.files.map(\.url),
            onDrop: { urls in
                withAnimation(.easeOut(duration: 0.28)) {
                    store.add(urls: urls)
                }
            },
            onDoubleClick: {
                // Stack shows the newest file on top — preview that one first.
                let urls = store.files.map(\.url)
                quickLook.preview(
                    urls: urls,
                    startingAt: max(urls.count - 1, 0)
                )
            }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.secondary)

            Text("Drop files here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var fileList: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(Array(store.files.enumerated()), id: \.element.id) {
                    index,
                    file in
                    fileRow(file, index: index)
                }
            }
            .padding(10)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleListDrop(providers: providers)
        }
    }

    private func fileRow(_ file: DroppedFile, index: Int) -> some View {
        HStack(spacing: 8) {
            FilePreviewView(file: file, size: 28)

            Text(file.name)
                .lineLimit(1)

            Spacer()

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    store.remove(file)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
        .onTapGesture(count: 2) {
            quickLook.preview(
                urls: store.files.map(\.url),
                startingAt: index
            )
        }
        // Lets the user drag one file from the list into Finder / other apps.
        .draggable(file.url) {
            FilePreviewView(file: file, size: 48)
        }
    }

    private var fileCountLabel: String {
        let count = store.files.count
        return count == 1 ? "1 file" : "\(count) files"
    }

    private func handleListDrop(providers: [NSItemProvider]) -> Bool {
        var didLoad = false

        for provider in providers {
            guard
                provider.hasItemConformingToTypeIdentifier(
                    UTType.fileURL.identifier
                )
            else {
                continue
            }

            didLoad = true

            provider.loadItem(
                forTypeIdentifier: UTType.fileURL.identifier,
                options: nil
            ) { item, _ in
                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let urlItem = item as? URL {
                    url = urlItem
                } else {
                    url = nil
                }

                guard let url else {
                    return
                }

                Task { @MainActor in
                    withAnimation(.easeOut(duration: 0.28)) {
                        store.add(urls: [url])
                    }
                }
            }
        }

        return didLoad
    }
}
