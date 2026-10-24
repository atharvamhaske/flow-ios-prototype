# Flow

A SwiftUI UI prototype for payments and shared expenses. Bundled Inter typography, white, soft lavender and pale lime; native sheets, press feedback and an animated demo receipt with Reduce Motion support.

Open `Flow.xcodeproj` in full Xcode. Select an iPhone Simulator and Run. For a physical iPhone, select your Personal Team under Signing & Capabilities. iOS 17+; macOS 14+.

The adjacent `Flow Preview.app` is a locally signed Apple Silicon Mac build. It is not notarized or intended for distribution.

## Available

- Home, sample groups and locally persisted activity.
- Demo payment: recipient, amount, review, animated receipt.
- Equal-split preview with exact paise allocation and local expense recording.

## Limits

No real UPI transfers, bank connection, QR scanner, group sync or per-person debt ledger yet. Transfers are explicitly simulated. Sample groups do not represent shared online accounts. iPhone builds and interactive UI tests require full Xcode and remain unverified here.

Run `./check.sh` for amount/split checks and Mac compilation. UI inspiration: the supplied screenshots and Emil Kowalski's design engineering, library selection and Swift skills. His web libraries are translated into native SwiftUI patterns; no web dependency is bundled. Appinspo's generator was inspected but did not produce a skill in this session.

Inter is bundled under the SIL Open Font License; see `Flow/Resources/OFL.txt`. Interaction motion uses shared 140–280 ms timing curves; the one-shot receipt reveal lasts 500 ms and respects Reduce Motion.

Payment-card artwork is an AI-generated bundled asset. The receipt dispenser is native SwiftUI, with a static Reduce Motion state.
