import Foundation
@main struct AmountChecks {
    static func main() {
        precondition(AmountInput.paise("123.45") == 12345)
        precondition(AmountInput.paise(" 1.5 ") == 150)
        for invalid in ["", "0", "-1", "1.234", "1e3", "1,000", "1.2.3", "１２", "99999999"] {
            precondition(AmountInput.paise(invalid) == nil, "Accepted invalid amount: \(invalid)")
        }
        precondition(AmountInput.equalShares(total: 100, count: 3) == [34, 33, 33])
        for total in [1, 99, 100, 10001, 999999999] {
            for count in 2...20 {
                let shares = AmountInput.equalShares(total: total, count: count)
                precondition(shares.reduce(0,+) == total)
                precondition((shares.max() ?? 0) - (shares.min() ?? 0) <= 1)
            }
        }
        print("PASS: amount validation and 95 split conservation cases")
    }
}
