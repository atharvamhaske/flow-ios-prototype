import SwiftUI

struct SplitSheet: View {
    let onSave: (ActivityItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var amount = ""
    @State private var people = 4
    @State private var saved = false
    private var shares: [Int] { AmountInput.equalShares(total: AmountInput.paise(amount) ?? 0, count: people) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("SPLIT A BILL").font(.caption2).tracking(2)
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                        .accessibilityLabel("Close split")
                }
                Text("Good times.\nEven splits.").font(.system(size: 43, weight: .medium)).tracking(-2)
                entry("What was it for?", placeholder: "Dinner, a trip, the little things…", text: $title)
                entry("You paid · Amount in rupees", placeholder: "0.00", text: $amount)
                Stepper("\(people) people, including you", value: $people, in: 2...20).padding(.vertical, 8)
                if !shares.isEmpty {
                    VStack(spacing: 14) {
                        ForEach(Array(shares.enumerated()), id: \.offset) { index, share in
                            HStack {
                                Text(index == 0 ? "Your share" : "Person \(index + 1)")
                                Spacer()
                                Text(money(share)).monospacedDigit()
                            }.font(.system(size: 14))
                        }
                    }.padding(22).background(Palette.lavender, in: RoundedRectangle(cornerRadius: 24))
                }
                Text("Equal split preview. Any extra paise go to the first participants. This records an expense locally; it does not notify friends.")
                    .font(.caption).foregroundStyle(Palette.muted)
                PrimaryButton(title: "Save shared expense", icon: "plus") {
                    guard !saved, let value = AmountInput.paise(amount) else { return }
                    saved = true
                    onSave(ActivityItem(title: title.trimmingCharacters(in: .whitespacesAndNewlines), subtitle: "Equal split · \(people) people · You paid", amount: value, symbol: "divide", isSplit: true))
                    dismiss()
                }.disabled(shares.isEmpty || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || saved)
                    .opacity(shares.isEmpty || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            }.padding(28)
        }.background(.white).foregroundStyle(Palette.ink).buttonStyle(PressStyle())
            .frame(idealWidth: 430, minHeight: 660)
    }
}
