import SwiftUI

@MainActor
final class PowerModesAppDelegate: NSObject, NSApplicationDelegate {
    weak var model: AppModel?

    func applicationWillTerminate(_ notification: Notification) {
        model?.endAuthorizationSession()
    }
}

@main
struct PowerModesApp: App {
    @NSApplicationDelegateAdaptor(PowerModesAppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuPopupView(model: model)
                .onAppear { appDelegate.model = model }
        } label: {
            Image(systemName: model.menuBarIconName)
                .accessibilityLabel("电源模式：\(model.selectedPreset?.name ?? "未选择")")
                .onAppear { appDelegate.model = model }
        }
        .menuBarExtraStyle(.window)

        Settings {
            MenuContentView(model: model)
                .frame(minWidth: 420, minHeight: 560)
                .onAppear { appDelegate.model = model }
        }
    }
}
