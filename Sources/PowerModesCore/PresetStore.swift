import Foundation

public struct PresetStore {
    private let defaults: UserDefaults
    private let key = "powerModes.presets.v1"
    private let presetTimesMigrationKey = "powerModes.defaults.v3Migrated"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() throws -> [PowerPreset] {
        guard let data = defaults.data(forKey: key) else {
            defaults.set(true, forKey: presetTimesMigrationKey)
            return PowerPreset.builtIns
        }
        var presets = try JSONDecoder().decode([PowerPreset].self, from: data)
        if !defaults.bool(forKey: presetTimesMigrationKey) {
            if let index = presets.firstIndex(where: { $0.name == "正常模式" }) {
                presets[index].batteryDisplaySleepMinutes = 15
                presets[index].acDisplaySleepMinutes = 30
            }
            if let index = presets.firstIndex(where: { $0.name == "长任务模式" }) {
                presets[index].batteryDisplaySleepMinutes = 10
                presets[index].acDisplaySleepMinutes = 20
            }
            try save(presets)
            defaults.set(true, forKey: presetTimesMigrationKey)
        }
        return presets
    }

    public func save(_ presets: [PowerPreset]) throws {
        defaults.set(try JSONEncoder().encode(presets), forKey: key)
    }
}
