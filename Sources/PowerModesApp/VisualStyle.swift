import SwiftUI

enum PowerTheme {
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let raised = Color(nsColor: .unemphasizedSelectedContentBackgroundColor)
    static let line = Color(nsColor: .separatorColor)
    static let text = Color(nsColor: .labelColor)
    static let muted = Color(nsColor: .secondaryLabelColor)
    static let live = Color(nsColor: .systemGreen)
    static let warning = Color(nsColor: .systemOrange)
}

struct FlatPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(nsColor: .windowBackgroundColor))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color(nsColor: .labelColor).opacity(configuration.isPressed ? 0.74 : 0.94))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct FlatSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(PowerTheme.text.opacity(configuration.isPressed ? 0.6 : 1))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(PowerTheme.raised.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}
