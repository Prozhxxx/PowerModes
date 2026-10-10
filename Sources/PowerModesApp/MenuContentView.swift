import SwiftUI
import PowerModesCore

struct MenuContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            liveStatus
                .padding(.top, 18)

            Text("预设")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(PowerTheme.muted)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.top, 24)
                .padding(.bottom, 8)

            VStack(spacing: 1) {
                ForEach(model.presets) { preset in presetRow(preset) }
            }
            .background(PowerTheme.line)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(PowerTheme.line, lineWidth: 1))

            HStack(spacing: 8) {
                Button { model.addPreset() } label: { Label("新建预设", systemImage: "plus") }
                    .buttonStyle(FlatSecondaryButtonStyle())
                Button { model.openLockScreenSettings() } label: { Label("锁屏设置", systemImage: "lock") }
                    .buttonStyle(FlatSecondaryButtonStyle())
                Spacer()
            }
            .padding(.top, 12)

            Spacer(minLength: 20)

            statusMessage
            Button { model.performPrimaryAction() } label: {
                HStack(spacing: 8) {
                    if model.isApplying { ProgressView().controlSize(.small).tint(PowerTheme.canvas) }
                    Text(primaryButtonTitle)
                }
            }
            .buttonStyle(FlatPrimaryButtonStyle())
            .disabled(model.selectedPreset == nil || model.isApplying)
            .padding(.top, 10)

            HStack {
                Label(model.authorizationState == .ready ? "本次运行无需再次授权" : "每次打开 App 授权一次", systemImage: "hand.raised")
                Spacer()
                Button("退出") { model.quit() }
                    .buttonStyle(.plain)
                    .foregroundStyle(PowerTheme.muted)
            }
            .font(.system(size: 10.5))
            .foregroundStyle(PowerTheme.muted)
            .padding(.top, 12)
        }
        .padding(22)
        .frame(width: 420)
        .frame(minHeight: 520)
        .background(PowerTheme.canvas)
        .sheet(item: $model.editingPreset) { preset in
            PresetEditorView(preset: preset, onSave: model.save)
        }
    }

    private var primaryButtonTitle: String {
        if model.isApplying {
            return model.authorizationState == .authorizing ? "正在授权" : "正在应用"
        }
        return switch model.authorizationState {
        case .ready: "应用模式"
        case .authorizing: "正在授权"
        case .failed: "请重新打开 App"
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("电源模式")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(PowerTheme.text)
                Text("选择一个方案，然后交给 macOS 执行。")
                    .font(.system(size: 12))
                    .foregroundStyle(PowerTheme.muted)
            }
            Spacer()
            Button { model.refresh() } label: {
                Image(systemName: "arrow.clockwise").font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(FlatSecondaryButtonStyle())
            .help("重新读取系统状态")
        }
    }

    private var liveStatus: some View {
        HStack(spacing: 10) {
            Circle().fill(PowerTheme.live).frame(width: 7, height: 7)
            Text("LIVE").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(0.8)
            Rectangle().fill(PowerTheme.line).frame(width: 1, height: 18)
            if let snapshot = model.snapshot {
                Text(snapshot.sourceDescription)
                Spacer()
                Image(systemName: snapshot.lidSleepDisabled ? "laptopcomputer.and.arrow.down" : "laptopcomputer")
                Text(snapshot.lidSleepDisabled ? "合盖继续" : "合盖睡眠")
            } else {
                Text("读取中")
                Spacer()
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(PowerTheme.text.opacity(0.86))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(PowerTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(PowerTheme.line, lineWidth: 1))
    }

    private var statusMessage: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: model.statusText.hasPrefix("✓") ? "checkmark.circle.fill" : "info.circle")
                .foregroundStyle(model.statusText.hasPrefix("✓") ? PowerTheme.live : PowerTheme.muted)
            Text(model.statusText).lineLimit(2)
            Spacer()
        }
        .font(.system(size: 11))
        .foregroundStyle(PowerTheme.muted)
    }

    @ViewBuilder
    private func presetRow(_ preset: PowerPreset) -> some View {
        let selected = model.selectedID == preset.id
        HStack(spacing: 12) {
            Circle()
                .fill(selected ? PowerTheme.text : .clear)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(selected ? PowerTheme.text : PowerTheme.muted, lineWidth: 1.2))
                .overlay(Circle().fill(PowerTheme.canvas).frame(width: 5, height: 5).opacity(selected ? 1 : 0))
            VStack(alignment: .leading, spacing: 3) {
                Text(preset.name).font(.system(size: 13, weight: .semibold)).foregroundStyle(PowerTheme.text)
                Text(summary(preset)).font(.system(size: 10.5)).foregroundStyle(PowerTheme.muted).lineLimit(1)
            }
            Spacer()
            Menu {
                Button("编辑") { model.editingPreset = preset }
                Button("删除", role: .destructive) { model.delete(preset) }
            } label: {
                Image(systemName: "ellipsis").frame(width: 24, height: 24).contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).foregroundStyle(PowerTheme.muted)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .background(selected ? PowerTheme.raised : PowerTheme.surface)
        .contentShape(Rectangle())
        .onTapGesture { model.selectedID = preset.id }
    }

    private func summary(_ preset: PowerPreset) -> String {
        let sleep = preset.allowSystemSleep ? "允许睡眠" : "系统不睡眠"
        let lid = preset.allowLidAwake ? "合盖继续" : "合盖睡眠"
        return "电池 \(preset.batteryDisplaySleepMinutes) 分钟  ·  接电 \(preset.acDisplaySleepMinutes) 分钟  ·  \(sleep)  ·  \(lid)"
    }
}
