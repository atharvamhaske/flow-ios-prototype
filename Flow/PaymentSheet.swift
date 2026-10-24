import SwiftUI
#if os(iOS)
import UIKit
#endif

struct CallAttempt: Identifiable, Codable {
    struct Event: Codable {
        let date: Date
        let status: String
    }
    let id: UUID
    let recipient: String
    let amount: Int
    var events: [Event]
}

struct PaymentSheet: View {
    let onComplete: (ActivityItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var recipient: String
    @State private var amount = ""
    @State private var reviewed = false
    @State private var acknowledged = false
    @State private var attempts: [CallAttempt] = []
    @State private var error: String?
    @State private var ready = false
    @State private var launching = false
    private let serviceNumber = "9188123123"
    private let source = URL(string: "https://www.pnb.bank.in/UPI-One-Two-Three-Pay.html")!

    init(initialRecipient: String = "", onComplete: @escaping (ActivityItem) -> Void) {
        self.onComplete = onComplete
        _recipient = State(initialValue: initialRecipient)
    }

    private var validRecipient: Bool {
        recipient.count == 10 && recipient.utf8.allSatisfy { (48...57).contains($0) }
    }

    private var historyURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Rello", isDirectory: true).appendingPathComponent("call-attempts.json")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("PAY BY PHONE").font(Typeface.font(11)).tracking(2)
                    Spacer()
                    Button("Close") { dismiss() }.frame(minHeight: 44)
                }
                Text("A call.\nA real payment.").font(Typeface.font(36, weight: .medium)).tracking(-1.2)
                Text("Guided UPI 123PAY · PNB-published service")
                    .font(Typeface.font(13)).foregroundStyle(Palette.muted)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bank setup happens in the call").font(Typeface.font(18, weight: .medium))
                    Text("Use your bank-registered SIM with cellular service. Follow the voice prompts to select or add a supported bank account. Rello cannot verify bank eligibility or link an account itself.")
                    Text("Enter any PIN or OTP only in the official phone service, never in Rello. Mobile data is not required for the call; carrier charges may apply.")
                    Link("Read PNB’s official instructions", destination: source)
                }.font(Typeface.font(13)).padding(20)
                    .background(Palette.lavender, in: RoundedRectangle(cornerRadius: 24))
                if !reviewed {
                    entry("Recipient mobile number", placeholder: "10-digit mobile number", text: $recipient)
                    entry("Amount in rupees", placeholder: "1.00", text: $amount)
                    Text("These details are your local reminder. You must enter them yourself in the phone service and verify the recipient there.")
                        .font(Typeface.font(12)).foregroundStyle(Palette.muted)
                    PrimaryButton(title: "Review phone payment") { reviewed = true }
                        .disabled(!validRecipient || AmountInput.paise(amount) == nil || !ready)
                } else {
                    Text("To \(recipient) · \(money(AmountInput.paise(amount) ?? 0))")
                        .font(Typeface.font(22, weight: .medium))
                    Text("Check previous attempts before retrying to avoid paying twice. Call \(serviceNumber), follow setup prompts, select a transfer, enter the recipient and amount, and verify the details before authorizing. After the call, return here to record what happened.")
                        .font(Typeface.font(14))
                    Toggle("I understand this service can move real money and requires my bank-registered SIM.", isOn: $acknowledged)
                        .font(Typeface.font(13))
                    #if os(iOS) && !targetEnvironment(simulator)
                    PrimaryButton(title: "Call 123PAY · \(serviceNumber)", icon: "phone") { startCall() }
                        .disabled(!acknowledged || !ready || launching)
                    #else
                    Text("Calling requires a physical iPhone. Mac and Simulator cannot test this payment route.")
                        .font(Typeface.font(14)).foregroundStyle(Palette.muted)
                    #endif
                    Button("Edit details") { reviewed = false; acknowledged = false }.frame(minHeight: 44)
                }
                if let error { Text(error).font(Typeface.font(13)).accessibilityLabel("Error: " + error) }
                Divider()
                Text("Phone payment history").font(Typeface.font(24, weight: .medium))
                Text("Saved on this device. Results are reported by you, never bank-confirmed. Opening or ending a call does not confirm payment.")
                    .font(Typeface.font(12)).foregroundStyle(Palette.muted)
                if attempts.isEmpty { Text("No phone payment attempts yet.").foregroundStyle(Palette.muted) }
                ForEach(attempts) { attempt in
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(attempt.recipient) · \(money(attempt.amount))").font(Typeface.font(18, weight: .medium))
                        Text(attempt.id.uuidString).font(Typeface.font(9)).textSelection(.enabled)
                        ForEach(Array(attempt.events.enumerated()), id: \.offset) { _, event in
                            Text("\(event.date.formatted(date: .abbreviated, time: .shortened)) · \(event.status)")
                                .font(Typeface.font(12))
                        }
                        Text("What happened? Report or correct the result.").font(Typeface.font(12))
                        HStack {
                            Button("Paid") { report(attempt.id, "Reported paid · Reported by you") }
                            Button("Failed") { report(attempt.id, "Reported failed · Reported by you") }
                            Button("Not sure") { report(attempt.id, "Awaiting confirmation · Reported by you") }
                        }.font(Typeface.font(13)).frame(minHeight: 44).disabled(!ready)
                    }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))
                }
            }.padding(28)
        }.background(.white).foregroundStyle(Palette.ink).buttonStyle(PressStyle())
            .frame(idealWidth: 430, minHeight: 620)
            .onAppear { loadHistory() }
    }

    private func loadHistory() {
        do {
            if FileManager.default.fileExists(atPath: historyURL.path) {
                attempts = try JSONDecoder().decode([CallAttempt].self, from: Data(contentsOf: historyURL))
            }
            ready = true
        } catch {
            ready = false
            self.error = "Saved phone history could not be read. It has been preserved; calls are disabled until it is recovered."
        }
    }

    @discardableResult private func save(_ updated: [CallAttempt]) -> Bool {
        do {
            let data = try JSONEncoder().encode(updated)
            try FileManager.default.createDirectory(at: historyURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: historyURL, options: .atomic)
            attempts = updated
            error = nil
            return true
        } catch {
            self.error = "Could not save phone history. No new call was started. Please try again."
            return false
        }
    }

    private func report(_ id: UUID, _ status: String) {
        var updated = attempts
        guard let index = updated.firstIndex(where: { $0.id == id }) else { return }
        updated[index].events.append(.init(date: Date(), status: status))
        save(updated)
    }

    private func startCall() {
        #if os(iOS) && !targetEnvironment(simulator)
        guard ready, acknowledged, !launching, validRecipient,
              let paise = AmountInput.paise(amount), let url = URL(string: "tel:" + serviceNumber) else { return }
        guard UIApplication.shared.canOpenURL(url) else {
            error = "Phone calls are unavailable on this device. No attempt was started."
            return
        }
        let attempt = CallAttempt(id: UUID(), recipient: recipient, amount: paise,
                                  events: [.init(date: Date(), status: "Awaiting confirmation · Call requested")])
        guard save([attempt] + attempts) else { return }
        launching = true
        UIApplication.shared.open(url, options: [:]) { opened in
            launching = false
            if !opened {
                report(attempt.id, "Phone handoff not opened · No bank result")
                error = "The phone handoff was cancelled or unavailable. No payment result is known."
            }
        }
        reviewed = false
        acknowledged = false
        #endif
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
                        Text("RELLO RECEIPT").font(Typeface.font(9, weight: .medium)).tracking(1.5)
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
