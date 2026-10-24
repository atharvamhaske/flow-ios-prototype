import SwiftUI

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
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String
    var icon = "arrow.up.right"
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).fontWeight(.semibold)
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
        Text(initials).font(.system(size: 14, weight: .semibold, design: .rounded))
            .frame(width: 44, height: 44)
            .background(color, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .accessibilityHidden(true)
    }
}

func money(_ paise: Int) -> String {
    (Double(paise) / 100).formatted(.currency(code: "INR").locale(Locale(identifier: "en_IN")))
}
