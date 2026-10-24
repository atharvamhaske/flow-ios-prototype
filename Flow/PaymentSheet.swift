import SwiftUI

struct PaymentSheet: View {
    let onComplete: (ActivityItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var recipient = ""
    @State private var amount = ""
    @State private var phase = Phase.edit
    enum Phase { case edit, review, receipt }
    init(initialRecipient: String = "", onComplete: @escaping (ActivityItem) -> Void) {
        self.onComplete = onComplete
        _recipient = State(initialValue: initialRecipient)
    }

    private var paise: Int? { AmountInput.paise(amount) }
    private var name: String { recipient.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Text("PAY SOMEONE").font(.caption2).tracking(2)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").frame(width: 44, height: 44)
                            .background(Palette.surface, in: Circle())
                    }.accessibilityLabel("Close payment")
                }
                switch phase {
                case .edit: editor
                case .review: review
                case .receipt:
                    ReceiptView(amount: paise ?? 0, recipient: name)
                    PrimaryButton(title: "Back to your day", icon: "checkmark") { dismiss() }
                }
            }.padding(28)
        }
        .background(.white).foregroundStyle(Palette.ink)
        .buttonStyle(PressStyle())
        .frame(idealWidth: 430, minHeight: 620)
        .interactiveDismissDisabled(phase == .receipt)
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Make their\nday.").font(.system(size: 46, weight: .medium)).tracking(-2)
            Text("Try the payment experience with demo money.").font(.subheadline).foregroundStyle(Palette.muted)
            entry("Recipient", placeholder: "Name or UPI ID", text: $recipient)
            entry("Amount in rupees", placeholder: "0.00", text: $amount)
            Text("Enter a positive amount with up to two decimal places.").font(.caption).foregroundStyle(Palette.muted)
            PrimaryButton(title: "Review demo payment") { phase = .review }
                .disabled(name.isEmpty || paise == nil)
                .opacity(name.isEmpty || paise == nil ? 0.45 : 1)
            Label("Demo only. No money will move.", systemImage: "info.circle")
                .font(.caption).foregroundStyle(Palette.muted)
        }
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("Looks good?").font(.system(size: 42, weight: .medium)).tracking(-2)
            VStack(alignment: .leading, spacing: 20) {
                Avatar(initials: String(name.prefix(2)).uppercased(), color: .white)
                Text("To \(name)").font(.title3)
                Text(money(paise ?? 0)).font(.system(size: 42, weight: .medium)).minimumScaleFactor(0.5).lineLimit(1)
                Text("SIMULATED TRANSFER").font(.caption2).tracking(1.5)
            }.padding(26).frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.lavender, in: RoundedRectangle(cornerRadius: 28))
            PrimaryButton(title: "Confirm demo payment", icon: "checkmark") {
                guard phase == .review, let value = paise else { return }
                onComplete(ActivityItem(title: name, subtitle: "Demo transfer · Just now", amount: value, symbol: "arrow.up.right", isSplit: false))
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.22)) { phase = .receipt }
            }
            Button("Edit details") { phase = .edit }.frame(maxWidth: .infinity, minHeight: 44)
            Text("This preview does not call a bank or UPI app.").font(.caption).foregroundStyle(Palette.muted)
        }
    }
}

func entry(_ label: String, placeholder: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(Palette.muted)
        TextField(placeholder, text: text)
            .textFieldStyle(.plain).font(.system(size: 20))
            .padding(18).background(Palette.surface, in: RoundedRectangle(cornerRadius: 18))
            .accessibilityLabel(label)
    }
}

struct ReceiptView: View {
    let amount: Int
    let recipient: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().stroke(Palette.lavender, lineWidth: 1.5)
                    .frame(width: 156, height: 156)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.9)
                Circle().fill(Palette.lime).frame(width: 116, height: 116)
                Checkmark().trim(from: 0, to: appeared ? 1 : 0)
                    .stroke(Palette.ink, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .frame(width: 44, height: 34)
            }.padding(.top, 18).accessibilityHidden(true)
            VStack(spacing: 8) {
                Text("A little joy, sent.").font(.system(size: 31, weight: .medium)).tracking(-1)
                Text("Demo payment complete").font(.subheadline).foregroundStyle(Palette.muted)
            }
            Text(money(amount)).font(.system(size: 48, weight: .medium, design: .rounded)).minimumScaleFactor(0.5).lineLimit(1)
            Text("to \(recipient)").foregroundStyle(Palette.muted)
            Divider()
            Label("Saved to your demo activity", systemImage: "checkmark.seal").font(.caption)
            Text("No real money was transferred.").font(.caption).foregroundStyle(Palette.muted)
        }.frame(maxWidth: .infinity)
            .padding(.bottom, 22)
            .onAppear {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.28)) { appeared = true }
            }
    }
}

struct Checkmark: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.width * 0.36, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
    }
}
