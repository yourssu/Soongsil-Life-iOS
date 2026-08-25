import Foundation

enum CurrencyFormatter {
    static func won(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmed.isEmpty else {
            return "0원"
        }

        return trimmed.hasSuffix("원")
            ? trimmed
            : "\(trimmed)원"
    }
}
