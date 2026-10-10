import Foundation

public enum PowerCommandBuilder {
    public static func commands(for preset: PowerPreset) throws -> [[String]] {
        guard (0...480).contains(preset.batteryDisplaySleepMinutes),
              (0...480).contains(preset.acDisplaySleepMinutes) else {
            throw PowerModesError.invalidMinutes
        }
        guard (5...80).contains(preset.lowBatteryCutoff) else {
            throw PowerModesError.invalidBatteryCutoff
        }
        let sleep = preset.allowSystemSleep ? "1" : "0"
        return [
            ["pmset", "-b", "displaysleep", String(preset.batteryDisplaySleepMinutes), "sleep", sleep],
            ["pmset", "-c", "displaysleep", String(preset.acDisplaySleepMinutes), "sleep", sleep],
            ["pmset", "-a", "disablesleep", preset.allowLidAwake ? "1" : "0"]
        ]
    }

    public static func elevatedShellCommand(for preset: PowerPreset) throws -> String {
        try commands(for: preset)
            .map { arguments in arguments.enumerated().map { index, value in index == 0 ? "/usr/bin/\(value)" : value }.joined(separator: " ") }
            .joined(separator: "; ")
    }
}
