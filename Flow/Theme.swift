import SwiftUI
import CoreText

enum Palette {
    static let ink = Color(red: 0.10, green: 0.11, blue: 0.10)
    static let muted = Color(red: 0.39, green: 0.40, blue: 0.38)
    static let lavender = Color(red: 0.91, green: 0.86, blue: 0.97)
    static let lime = Color(red: 0.94, green: 0.96, blue: 0.74)
    static let surface = Color(red: 0.97, green: 0.97, blue: 0.96)
}

struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(Motion.press, value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String
    var icon = "arrow.up.right"
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(Typeface.font(15, weight: .semibold))
                Spacer()
                Image(systemName: icon)
            }
            .padding(20)
            .foregroundStyle(Palette.ink)
            .background(Palette.lime, in: RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(PressStyle())
    }
}

struct Avatar: View {
    let initials: String
    var color = Palette.lavender
    var body: some View {
        Text(initials).font(Typeface.font(14, weight: .semibold))
            .frame(width: 44, height: 44)
            .background(color, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .accessibilityHidden(true)
    }
}

func money(_ paise: Int) -> String {
    (Double(paise) / 100).formatted(.currency(code: "INR").locale(Locale(identifier: "en_IN")))
}


enum Typeface {
    static func register(from url: URL? = nil) {
        let fontURL = url ?? Bundle.main.url(forResource: "Inter", withExtension: "ttf", subdirectory: "Resources")
            ?? Bundle.main.url(forResource: "Inter", withExtension: "ttf")
        guard let fontURL else { fatalError("The bundled Inter font is missing") }
        var error: Unmanaged<CFError>?
        guard CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) else {
            fatalError("Inter registration failed: \(String(describing: error?.takeRetainedValue()))")
        }
    }

    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let style: Font.TextStyle = size >= 30 ? .largeTitle : size >= 20 ? .title2 : size >= 14 ? .body : .caption
        return .custom("Inter-Regular", size: size, relativeTo: style).weight(weight)
    }
}

enum Motion {
    static let press = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.14)
    static let transition = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.22)
    static let receipt = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.28)
}
