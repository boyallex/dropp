import SwiftUI

/// Composes overlapping file cards. Newest files sit on top.
struct FileStackView: View {

    let files: [DroppedFile]

    /// Limit layers so 30 files still look like a tidy pile, not a tower.
    private let maxVisibleLayers = 5
    private let cardSize: CGFloat = 148
    private let stackSize: CGFloat = 180

    var body: some View {
        let visibleFiles = Array(files.suffix(maxVisibleLayers))

        ZStack {
            ForEach(Array(visibleFiles.enumerated()), id: \.element.id) {
                index,
                file in

                let layerFromBottom = index
                let layerFromTop = visibleFiles.count - 1 - index

                FilePreviewView(file: file, size: cardSize)
                    .offset(
                        x: CGFloat(layerFromBottom) * 5,
                        y: CGFloat(layerFromBottom) * 5
                    )
                    // Small alternating tilt keeps the pile readable, not chaotic.
                    .rotationEffect(
                        .degrees(rotation(for: layerFromBottom))
                    )
                    .zIndex(Double(index))
                    .opacity(opacity(for: layerFromTop))
                    .transition(
                        .scale(scale: 0.85)
                            .combined(with: .opacity)
                    )
            }
        }
        .frame(width: stackSize, height: stackSize)
        .animation(
            .easeOut(duration: 0.28),
            value: files.map(\.id)
        )
    }

    private func rotation(for layerFromBottom: Int) -> Double {
        let angles: [Double] = [-3.5, 2.0, -1.5, 3.0, 0]
        let safeIndex = min(layerFromBottom, angles.count - 1)
        return angles[safeIndex]
    }

    private func opacity(for layerFromTop: Int) -> Double {
        // Deeper cards stay slightly softer so the top preview leads the eye.
        switch layerFromTop {
        case 0:
            return 1
        case 1:
            return 0.96
        case 2:
            return 0.9
        default:
            return 0.82
        }
    }
}
