import SwiftUI

struct ZoomableChapelSeatMapView: View {
    let seat: String

    @State private var zoomScale: CGFloat = 1
    @State private var lastZoomScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let mapWidth: CGFloat = 820
    private let mapHeight: CGFloat = 620

    private var seatLocation: ChapelSeatLocation {
        ChapelSeatLocation(seat: seat)
    }

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { proxy in
                let fitScale = min(
                    proxy.size.width / mapWidth,
                    proxy.size.height / mapHeight
                )
                let contentSize = scaledContentSize(fitScale: fitScale)
                let boundedOffset = clampedOffset(
                    offset,
                    contentSize: contentSize,
                    containerSize: proxy.size
                )

                ChapelSeatMapContentView(seatLocation: seatLocation)
                    .frame(width: mapWidth, height: mapHeight)
                    .scaleEffect(fitScale * zoomScale)
                    .frame(
                        width: contentSize.width,
                        height: contentSize.height
                    )
                    .position(
                        x: proxy.size.width / 2 + boundedOffset.width,
                        y: proxy.size.height / 2 + boundedOffset.height
                    )
                    .gesture(
                        magnificationGesture(
                            fitScale: fitScale,
                            containerSize: proxy.size
                        )
                    )
                    .simultaneousGesture(
                        dragGesture(
                            fitScale: fitScale,
                            containerSize: proxy.size
                        )
                    )
            }
            .frame(height: 300)
            .clipped()

            Text("자리를 확인해주세요")
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(.serviceBlue500)
        }
        .padding(.top, 20)
        .padding(.bottom, 19)
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity)
        .background(.white000)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.gray100, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: resetTransform)
        .accessibilityElement(children: .contain)
    }

    private func magnificationGesture(
        fitScale: CGFloat,
        containerSize: CGSize
    ) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = min(max(lastZoomScale * value, 1), 4)
                zoomScale = newScale
                offset = clampedOffset(
                    offset,
                    contentSize: scaledContentSize(
                        fitScale: fitScale,
                        zoomScale: newScale
                    ),
                    containerSize: containerSize
                )
            }
            .onEnded { _ in
                zoomScale = min(max(zoomScale, 1), 4)
                lastZoomScale = zoomScale
                offset = clampedOffset(
                    offset,
                    contentSize: scaledContentSize(fitScale: fitScale),
                    containerSize: containerSize
                )
                lastOffset = offset
            }
    }

    private func dragGesture(
        fitScale: CGFloat,
        containerSize: CGSize
    ) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard zoomScale > 1 else {
                    return
                }

                offset = clampedOffset(
                    CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    ),
                    contentSize: scaledContentSize(fitScale: fitScale),
                    containerSize: containerSize
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func scaledContentSize(
        fitScale: CGFloat,
        zoomScale: CGFloat? = nil
    ) -> CGSize {
        let scale = zoomScale ?? self.zoomScale
        return CGSize(
            width: mapWidth * fitScale * scale,
            height: mapHeight * fitScale * scale
        )
    }

    private func clampedOffset(
        _ offset: CGSize,
        contentSize: CGSize,
        containerSize: CGSize
    ) -> CGSize {
        let maxX = max((contentSize.width - containerSize.width) / 2, 0)
        let maxY = max((contentSize.height - containerSize.height) / 2, 0)

        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }

    private func resetTransform() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = 1
            lastZoomScale = 1
            offset = .zero
            lastOffset = .zero
        }
    }
}

private struct ChapelSeatMapContentView: View {
    let seatLocation: ChapelSeatLocation

    private let zoneRows: [[ChapelSeatZone]] = [
        [.a, .b, .c, .d, .e],
        [.f, .g, .h, .i, .j]
    ]

    var body: some View {
        VStack(spacing: 28) {
            Text("STAGE")
                .font(.pretendard(28, weight: .semibold))
                .foregroundStyle(.white000)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(.gray700)

            VStack(spacing: 38) {
                ForEach(zoneRows.indices, id: \.self) { rowIndex in
                    HStack(alignment: .top, spacing: 22) {
                        ForEach(zoneRows[rowIndex]) { zone in
                            ChapelSeatZoneView(
                                zone: zone,
                                seatLocation: seatLocation
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 24)
        .background(.white000)
    }
}

private struct ChapelSeatZoneView: View {
    let zone: ChapelSeatZone
    let seatLocation: ChapelSeatLocation

    private let seatSize: CGFloat = 7
    private let seatGap: CGFloat = 3
    private let aisleHeight: CGFloat = 10

    private var selectedRow: Int? {
        seatLocation.zone == zone.id ? seatLocation.row : nil
    }

    private var selectedColumn: Int? {
        seatLocation.zone == zone.id ? seatLocation.column : nil
    }

    private var zoneWidth: CGFloat {
        CGFloat(zone.columns) * seatSize
            + CGFloat(zone.columns - 1) * seatGap
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(zone.id)
                .font(.pretendard(15, weight: .semibold))
                .foregroundStyle(.gray700)

            VStack(spacing: seatGap) {
                ForEach(zone.rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: seatGap) {
                        ForEach(
                            zone.rows[rowIndex].seats.indices,
                            id: \.self
                        ) { columnIndex in
                            seatSlot(
                                column: zone.rows[rowIndex].seats[columnIndex],
                                row: rowIndex + 1
                            )
                        }
                    }

                    if zone.aisleAfterRows.contains(rowIndex + 1) {
                        Spacer()
                            .frame(height: aisleHeight)
                    }
                }
            }
            .frame(width: zoneWidth)
        }
        .frame(width: 118)
    }

    @ViewBuilder
    private func seatSlot(column: Int?, row: Int) -> some View {
        if let column {
            seatView(row: row, column: column)
        } else {
            Color.clear
                .frame(width: seatSize, height: seatSize)
        }
    }

    private func seatView(row: Int, column: Int) -> some View {
        let isSelected = selectedRow == row && selectedColumn == column

        return RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(
                isSelected
                    ? .serviceBlue500
                    : .serviceGray200
            )
            .frame(width: seatSize, height: seatSize)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(
                            .serviceBlue500.opacity(0.35),
                            lineWidth: 4
                        )
                }
            }
            .accessibilityLabel(
                L10n.Chapel.seatAccessibilityLabel(
                    zone: zone.id,
                    row: row,
                    column: column
                )
            )
    }
}

#Preview("Seat map · compact seat") {
    ZoomableChapelSeatMapView(seat: "B-12")
        .padding(24)
        .background(.white000)
}

#Preview("Seat map · explicit row and column") {
    ZoomableChapelSeatMapView(seat: "H-1-4")
        .padding(24)
        .background(.white000)
}
