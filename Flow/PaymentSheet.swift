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
                    Text("PAY SOMEONE").font(Typeface.font(11)).tracking(2)
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
        .sensoryFeedback(.success, trigger: phase == .receipt)
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Make their\nday.").font(Typeface.font(36, weight: .medium)).tracking(-1.2)
                Spacer(minLength: 0)
                PaymentArtwork().frame(width: 145, height: 135)
            }
            Text("Try the payment experience with demo money.").font(Typeface.font(14)).foregroundStyle(Palette.muted)
            entry("Recipient", placeholder: "Name or UPI ID", text: $recipient)
            entry("Amount in rupees", placeholder: "0.00", text: $amount)
            Text("Enter a positive amount with up to two decimal places.").font(Typeface.font(12)).foregroundStyle(Palette.muted)
            PrimaryButton(title: "Review demo payment") { phase = .review }
                .disabled(name.isEmpty || paise == nil)
                .opacity(name.isEmpty || paise == nil ? 0.45 : 1)
            Label("Demo only. No money will move.", systemImage: "info.circle")
                .font(Typeface.font(12)).foregroundStyle(Palette.muted)
        }
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text("Looks good?").font(Typeface.font(42, weight: .medium)).tracking(-2)
            VStack(alignment: .leading, spacing: 20) {
                Avatar(initials: String(name.prefix(2)).uppercased(), color: .white)
                Text("To \(name)").font(Typeface.font(20))
                Text(money(paise ?? 0)).font(Typeface.font(42, weight: .medium)).minimumScaleFactor(0.5).lineLimit(1)
                Text("SIMULATED TRANSFER").font(Typeface.font(11)).tracking(1.5)
            }.padding(26).frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.lavender, in: RoundedRectangle(cornerRadius: 28))
            PrimaryButton(title: "Confirm demo payment", icon: "checkmark") {
                guard phase == .review, let value = paise else { return }
                onComplete(ActivityItem(title: name, subtitle: "Demo transfer · Just now", amount: value, symbol: "arrow.up.right", isSplit: false))
                withAnimation(reduceMotion ? nil : Motion.transition) { phase = .receipt }
            }
            Button("Edit details") { phase = .edit }.frame(maxWidth: .infinity, minHeight: 44)
            Text("This preview does not call a bank or UPI app.").font(Typeface.font(12)).foregroundStyle(Palette.muted)
        }
    }
}

func entry(_ label: String, placeholder: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 10) {
        Text(label).font(Typeface.font(12, weight: .medium)).foregroundStyle(Palette.muted)
        TextField(placeholder, text: text)
            .textFieldStyle(.plain).font(Typeface.font(20, weight: .regular))
            .padding(18).background(Palette.surface, in: RoundedRectangle(cornerRadius: 18))
            .accessibilityLabel(label)
    }
}

struct ReceiptView: View {
    let amount: Int
    let recipient: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    var showsFinalState = false
    var body: some View {
        VStack(spacing: 24) {
            ReceiptDispenser(progress: appeared || showsFinalState || reduceMotion ? 1 : 0)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text("All squared up.").font(Typeface.font(31, weight: .medium)).tracking(-1)
                Text("Demo payment complete").font(Typeface.font(14)).foregroundStyle(Palette.muted)
            }
            Text(money(amount)).font(Typeface.font(48, weight: .medium)).minimumScaleFactor(0.5).lineLimit(1)
            Text(verbatim: "to " + recipient).font(Typeface.font(15)).foregroundStyle(Palette.muted)
                .frame(maxWidth: .infinity, alignment: .center)
            HStack {
                Text("PAYMENT TYPE").font(Typeface.font(10, weight: .medium)).tracking(1)
                Spacer()
                Text("Demo transfer").font(Typeface.font(13, weight: .medium))
            }.padding(18).background(Palette.lavender.opacity(0.45), in: RoundedRectangle(cornerRadius: 18))
            Label("Saved to your demo activity", systemImage: "checkmark.seal").font(Typeface.font(12))
            Text("No real money was transferred.").font(Typeface.font(12)).foregroundStyle(Palette.muted)
        }.frame(maxWidth: .infinity)
            .padding(.bottom, 22)
            .onAppear {
                withAnimation(reduceMotion ? nil : Motion.dispense) { appeared = true }
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


struct ReceiptDispenser: View {
    var progress: CGFloat
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 25)
                .fill(Palette.lavender.gradient)
                .frame(width: 270, height: 96)
                .overlay(alignment: .topLeading) {
                    HStack(spacing: 5) {
                        Circle().fill(Palette.ink).frame(width: 5, height: 5)
                        Text("FLOW RECEIPT").font(Typeface.font(9, weight: .medium)).tracking(1.5)
                    }.padding(18)
                }
            Capsule().fill(Palette.ink).frame(width: 224, height: 12).offset(y: 60)
            VStack(spacing: 12) {
                HStack {
                    Text("ALL SQUARE").font(Typeface.font(9, weight: .semibold)).tracking(1.2)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                ZStack {
                    Circle().fill(Palette.lime).frame(width: 52, height: 52)
                    Checkmark().trim(from: 0, to: progress)
                        .stroke(Palette.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .frame(width: 20, height: 16)
                }
                Rectangle().fill(Palette.ink.opacity(0.12)).frame(height: 1)
                HStack(spacing: 4) {
                    ForEach(0..<24) { index in
                        Rectangle().fill(Palette.ink.opacity(0.65))
                            .frame(width: index.isMultiple(of: 3) ? 3 : 1, height: 20)
                    }
                }
                Text("DEMO · NO MONEY MOVED").font(Typeface.font(8, weight: .medium)).tracking(0.4)
            }
            .padding(18).frame(width: 198)
            .background(.white, in: RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Palette.ink.opacity(0.06)))
            .shadow(color: Palette.ink.opacity(0.09), radius: 10, y: 8)
            .offset(y: -205 * (1 - progress))
            .frame(height: 210, alignment: .top)
            .clipped()
            .padding(.top, 66)
            Capsule().fill(Palette.ink.opacity(0.7)).frame(width: 224, height: 3).offset(y: 60)
        }.frame(maxWidth: .infinity).frame(height: 285)
    }
}
