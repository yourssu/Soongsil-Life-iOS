import Foundation

struct ChapelSeatZone: Identifiable {
    let id: String
    let columns: Int
    let rows: [ChapelSeatRow]
    let aisleAfterRows: Set<Int>
    let entranceDirection: ChapelSeatEntranceDirection
}

struct ChapelSeatRow {
    let seats: [Int?]

    var seatCount: Int {
        seats.compactMap { $0 }.count
    }
}

enum ChapelSeatEntranceDirection {
    case left
    case right

    var localizedName: String {
        switch self {
        case .left:
            L10n.Chapel.leftDirection
        case .right:
            L10n.Chapel.rightDirection
        }
    }
}

struct ChapelSeatLocation {
    let zone: String
    let row: Int?
    let column: Int?

    init(seat: String) {
        let parts = seat
            .components(separatedBy: "-")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        zone = parts.first?.uppercased() ?? ChapelSeatZone.a.id

        if parts.count >= 3 {
            row = Int(parts[1])
            column = Int(parts[2])
        } else if let seatNumber = parts.dropFirst().first.flatMap(Int.init) {
            row = ((seatNumber - 1) / 4) + 1
            column = ((seatNumber - 1) % 4) + 1
        } else {
            row = nil
            column = nil
        }
    }

    var guideText: String {
        guard let zoneDefinition = ChapelSeatZone.definition(for: zone) else {
            return L10n.Chapel.seatGuideDefault
        }

        let direction = zoneDefinition.entranceDirection(
            row: row,
            column: column
        )
        let seatIndex = zoneDefinition.seatIndexFromEntrance(
            row: row,
            column: column
        )

        return L10n.Chapel.seatGuide(
            entranceDirection: direction.localizedName,
            row: row,
            seatIndexFromEntrance: seatIndex
        )
    }
}

extension ChapelSeatZone {
    func entranceDirection(
        row: Int?,
        column: Int?
    ) -> ChapelSeatEntranceDirection {
        guard [Self.c.id, Self.h.id].contains(id),
              let row,
              let column,
              rows.indices.contains(row - 1) else {
            return entranceDirection
        }

        let seatCount = rows[row - 1].seatCount
        return column <= Int(ceil(Double(seatCount) / 2))
            ? .left
            : .right
    }

    func seatIndexFromEntrance(
        row: Int?,
        column: Int?
    ) -> Int? {
        guard let row,
              let column,
              rows.indices.contains(row - 1) else {
            return nil
        }

        let selectedRow = rows[row - 1]
        guard selectedRow.seats.contains(column) else {
            return nil
        }

        switch entranceDirection(row: row, column: column) {
        case .left:
            return column
        case .right:
            return selectedRow.seatCount - column + 1
        }
    }
}
