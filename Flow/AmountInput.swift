import Foundation

enum AmountInput {
    static func paise(_ input: String) -> Int? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...2).contains(parts.count),
              !parts[0].isEmpty,
              parts[0].count <= 7,
              parts.allSatisfy({ $0.allSatisfy({ $0.isASCII && $0.isNumber }) }),
              let whole = Int(parts[0]) else { return nil }
        let fraction = parts.count == 2 ? String(parts[1]) : ""
        guard fraction.count <= 2 else { return nil }
        let padded = fraction.padding(toLength: 2, withPad: "0", startingAt: 0)
        guard let cents = Int(padded) else { return nil }
        let result = whole * 100 + cents
        return result > 0 ? result : nil
    }

    static func equalShares(total: Int, count: Int) -> [Int] {
        guard total > 0, (2...20).contains(count) else { return [] }
        return (0..<count).map { total / count + ($0 < total % count ? 1 : 0) }
    }
}
