import SwiftUI
import PowerModesCore

struct PresetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var preset: PowerPreset
    let onSave: (PowerPreset) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("编辑预设").font(.system(size: 22, weight: .bold, design: .rounded))
            Text("保存后不会立即改变系统设置。")
                .font(.system(size: 11)).foregroundStyle(PowerTheme.muted)
            TextField("名称", text: $preset.name)
                .textFieldStyle(.plain)
                .padding(10)
                .background(PowerTheme.raised, in: RoundedRectangle(cornerRadius: 8))
            Stepper("电池关屏：\(preset.batteryDisplaySleepMinutes) 分钟", value: $preset.batteryDisplaySleepMinutes, in: 0...480)
            Stepper("插电关屏：\(preset.acDisplaySleepMinutes) 分钟", value: $preset.acDisplaySleepMinutes, in: 0...480)
            Toggle("允许系统自动睡眠", isOn: $preset.allowSystemSleep).tint(PowerTheme.text)
            Toggle("合盖后继续运行", isOn: $preset.allowLidAwake).tint(PowerTheme.text)
            if preset.allowLidAwake {
                Stepper("低于 \(preset.lowBatteryCutoff)% 时提醒恢复", value: $preset.lowBatteryCutoff, in: 5...80, step: 5)
                Text("合盖继续运行可能导致发热和耗电，请勿放入电脑包。")
                    .font(.caption).foregroundStyle(PowerTheme.warning)
            }
            HStack {
                Button("取消") { dismiss() }.buttonStyle(FlatSecondaryButtonStyle())
                Spacer()
                Button("保存") { onSave(preset) }.buttonStyle(FlatPrimaryButtonStyle()).frame(width: 120).disabled(preset.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
        .background(PowerTheme.canvas)
    }
}
