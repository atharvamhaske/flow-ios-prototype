import SwiftUI

@main
struct FlowApp: App {
    var body: some Scene {
        WindowGroup {
            FlowHome()
                .preferredColorScheme(.light)
                #if os(macOS)
                .frame(minWidth: 390, idealWidth: 430, maxWidth: 560, minHeight: 740)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 430, height: 860)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
