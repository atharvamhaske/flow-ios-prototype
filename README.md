# Rello

A SwiftUI UI prototype for payments and shared expenses. Bundled Inter typography, white, soft lavender and pale lime; native sheets, press feedback and an animated demo receipt with Reduce Motion support.

Open `Flow.xcodeproj` in full Xcode. Select the Rello target, an iPhone Simulator and Run. For a physical iPhone, select your Personal Team under Signing & Capabilities. iOS 17+; macOS 14+.

The adjacent `Rello Preview.app` is a locally signed Apple Silicon Mac build. It is not notarized or intended for distribution.

## Available

- Home and locally persisted activity, starting empty. Recent people come from your own entries.
- Demo payment: recipient, amount, review, animated receipt.
- Equal-split preview with exact paise allocation and local expense recording.

## Test Now

The current build tests the UI and local storage only. It cannot send money to a mobile number or UPI ID, launch a payment app, or confirm a bank payment.

### On This Mac

1. Open the adjacent `Rello Preview.app` in the local outputs folder. The prebuilt app is not included in this GitHub repository.
2. Select `Pay someone`, enter a recipient label and a small demo amount such as ₹1, then review and confirm the demo payment.
3. Check the animated receipt and the new entry under Activity. No money moves.
4. Quit and reopen the app to check that the entry persists.
5. Try `Split a bill`, enter ₹100 and three people, and check that the shares total ₹100.
6. Turn off Wi-Fi and repeat a demo payment or expense entry. Local recording should still work; this does not demonstrate offline UPI.

A fresh installation starts empty. Existing user-created entries remain on this device. Invalid or zero amounts should prevent continuing to review.

### On iPhone Or Simulator

Open `Flow.xcodeproj` in full Xcode, select the Rello target and an iPhone Simulator, then Run. For a physical iPhone, connect the device, select your Personal Team under Signing & Capabilities, choose the device as the run destination, and follow Xcode's signing and device setup prompts.

Full Xcode is required; Command Line Tools alone cannot build this iPhone app. iPhone execution has not yet been verified. The same demo-only limitation applies on iPhone.

## Planned Local Payment-Attempt History

This workaround is a proposed next feature, not part of the current build. Current activity contains only recorded expenses and simulated payments.

- Before opening a UPI app or starting a payment call, save the recipient, amount, timestamp, and a unique attempt ID locally.
- When the user returns, ask: “Paid”, “Failed”, or “Not sure”.
- Label the answer “Reported by you”, separate from any bank-confirmed status. “Not sure” or no answer leaves the attempt awaiting confirmation.
- Optionally allow a receipt screenshot attachment or a manually entered UPI reference number.
- Keep the log on the device so history can be viewed and updated without internet.

The timeline would show “Awaiting confirmation”, “Reported paid”, and “Reported failed”. Returning to Rello, closing a payment app, or losing connectivity must never automatically imply success or failure.

This records attempts started through Rello. It will not automatically discover payments made elsewhere. Screenshots and manually entered reference numbers are supporting evidence, not bank verification. Verified status requires a supported payment provider integration.

Offline history is not offline money transfer. Payment-app handoff and phone-call payment support also still need implementation.

## Limits

No real UPI transfers, bank connection, QR scanner, group sync or per-person debt ledger yet. Transfers are explicitly simulated. Groups show an empty state until group support is implemented. Legacy seeded activity is removed on load; user-created entries are preserved. iPhone builds and interactive UI tests require full Xcode and remain unverified here.

Run `./check.sh` for amount/split checks and Mac compilation. UI inspiration: the supplied screenshots and Emil Kowalski's design engineering, library selection and Swift skills. His web libraries are translated into native SwiftUI patterns; no web dependency is bundled. Appinspo's generator was inspected but did not produce a skill in this session.

Inter is bundled under the SIL Open Font License; see `Flow/Resources/OFL.txt`. Interaction motion uses shared 140–280 ms timing curves; the one-shot receipt reveal lasts 500 ms and respects Reduce Motion.

Payment-card artwork is an AI-generated bundled asset. The receipt dispenser is native SwiftUI, with a static Reduce Motion state.
