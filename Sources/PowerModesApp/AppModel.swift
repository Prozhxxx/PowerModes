import AppKit
import Foundation
import PowerModesCore

@MainActor
final class AppModel: ObservableObject {
    enum AuthorizationState {
        case authorizing
        case ready
        case failed
    }

    @Published var presets: [PowerPreset] = []
    @Published var selectedID: UUID?
    @Published var snapshot: PowerSettingsSnapshot?
    @Published var statusText = "正在读取系统设置…"
    @Published var isApplying = false
    @Published var editingPreset: PowerPreset?
    @Published var authorizationState: AuthorizationState = .authorizing

    private let store = PresetStore()
    private let reader = PowerSettingsReader()
    private let applier = PowerSettingsApplier()
    private var authorizationSession: PowerAuthorizationSession?

    init() {
        do { presets = try store.load() } catch { presets = PowerPreset.builtIns }
        selectedID = presets.first?.id
        refresh()
        authorizeForThisRun()
    }

    var selectedPreset: PowerPreset? { presets.first { $0.id == selectedID } }

    var menuBarIconName: String {
        guard let preset = selectedPreset else { return "power" }
        if preset.allowLidAwake { return "laptopcomputer" }
        if !preset.allowSystemSleep { return "bolt.fill" }
        return "leaf.fill"
    }

    func refresh() {
        do {
            snapshot = try reader.read()
            statusText = "已读取当前设置"
        } catch {
            statusText = error.localizedDescription
        }
    }

    func authorizeForThisRun() {
        guard authorizationState != .ready else { return }
        authorizationState = .authorizing
        isApplying = true
        statusText = "打开 App 需要授权一次…"
        let helperPath = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Helpers/PowerModesHelper").path
        let user = NSUserName()
        let pid = Int(ProcessInfo.processInfo.processIdentifier)
        let applier = self.applier
        Task {
            do {
                let session = try await Task.detached {
                    try applier.beginSession(helperSource: helperPath, user: user, pid: pid)
                }.value
                authorizationSession = session
                authorizationState = .ready
                statusText = "✓ 本次运行已授权"
            } catch {
                authorizationState = .failed
                statusText = error.localizedDescription
            }
            isApplying = false
        }
    }

    func performPrimaryAction() {
        guard authorizationState == .ready else {
            statusText = "请退出并重新打开 App 完成启动授权"
            return
        }
        applySelected()
    }

    func selectAndApply(_ preset: PowerPreset) {
        guard !isApplying, authorizationState == .ready else { return }
        selectedID = preset.id
        applySelected()
    }

    private func applySelected() {
        guard let preset = selectedPreset else { return }
        guard let session = authorizationSession else {
            authorizationState = .failed
            statusText = "本次运行尚未授权"
            return
        }
        isApplying = true
        statusText = "正在应用 \(preset.name)…"
        let applier = self.applier
        Task {
            do {
                try await Task.detached { try applier.apply(preset, session: session) }.value
                try await Task.sleep(for: .milliseconds(600))
                let current = try reader.read()
                snapshot = current
                let result = current.verify(against: preset)
                statusText = result.isVerified ? "✓ \(preset.name) 已验证生效" : "部分未生效：\(result.mismatches.joined(separator: "、"))"
            } catch {
                statusText = error.localizedDescription
                authorizationState = .failed
                authorizationSession = nil
            }
            isApplying = false
        }
    }

    func endAuthorizationSession() {
        guard let session = authorizationSession else { return }
        applier.endSession(session)
        authorizationSession = nil
    }

    func quit() {
        endAuthorizationSession()
        NSApplication.shared.terminate(nil)
    }

    func save(_ preset: PowerPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) { presets[index] = preset }
        else { presets.append(preset) }
        selectedID = preset.id
        try? store.save(presets)
        editingPreset = nil
    }

    func addPreset() {
        editingPreset = PowerPreset(name: "自定义模式", batteryDisplaySleepMinutes: 10, acDisplaySleepMinutes: 5, allowSystemSleep: true, allowLidAwake: false, duration: .minutes(60))
    }

    func delete(_ preset: PowerPreset) {
        guard presets.count > 1 else { return }
        presets.removeAll { $0.id == preset.id }
        selectedID = presets.first?.id
        try? store.save(presets)
    }

    func openLockScreenSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
