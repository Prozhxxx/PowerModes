import AppKit
import SwiftUI
import PowerModesCore

struct MenuPopupView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("电源模式")
                        .font(.system(size: 15, weight: .semibold))
                    Text(authorizationText)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if model.isApplying { ProgressView().controlSize(.small) }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            VStack(spacing: 4) {
                ForEach(model.presets) { preset in presetButton(preset) }
            }
            .padding(8)

            Divider()

            HStack {
                Button {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    openSettings()
                } label: {
                    Label("设置…", systemImage: "gearshape")
                }
                .buttonStyle(.plain)
                Spacer()
                Button("退出") { model.quit() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 11.5))
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
        }
        .frame(width: 320)
    }

    private var authorizationText: String {
        switch model.authorizationState {
        case .authorizing: "启动授权中…"
        case .ready: "已授权，本次运行可直接切换"
        case .failed: "启动授权失败，请重新打开 App"
        }
    }

    private func presetButton(_ preset: PowerPreset) -> some View {
        let selected = model.selectedID == preset.id
        return Button {
            model.selectAndApply(preset)
        } label: {
            HStack(spacing: 11) {
                Image(systemName: iconName(for: preset))
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name).font(.system(size: 12.5, weight: .medium))
                    Text(summary(preset))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(selected ? Color.primary.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(model.authorizationState != .ready || model.isApplying)
    }

    private func iconName(for preset: PowerPreset) -> String {
        if preset.allowLidAwake { return "laptopcomputer" }
        if !preset.allowSystemSleep { return "bolt.fill" }
        return "leaf.fill"
    }

    private func summary(_ preset: PowerPreset) -> String {
        if preset.allowLidAwake { return "合盖继续运行" }
        if !preset.allowSystemSleep { return "保持唤醒，合盖睡眠" }
        return "电池 \(preset.batteryDisplaySleepMinutes) 分钟 · 接电 \(preset.acDisplaySleepMinutes) 分钟"
    }
}
