import Foundation

public enum SessionDuration: Codable, Equatable, Sendable {
    case minutes(Int)
    case infinite
}

public struct PowerPreset: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var batteryDisplaySleepMinutes: Int
    public var acDisplaySleepMinutes: Int
    public var allowSystemSleep: Bool
    public var allowLidAwake: Bool
    public var duration: SessionDuration
    public var lowBatteryCutoff: Int

    public init(
        id: UUID = UUID(),
        name: String,
        batteryDisplaySleepMinutes: Int,
        acDisplaySleepMinutes: Int,
        allowSystemSleep: Bool,
        allowLidAwake: Bool,
        duration: SessionDuration,
        lowBatteryCutoff: Int = 20
    ) {
        self.id = id
        self.name = name
        self.batteryDisplaySleepMinutes = batteryDisplaySleepMinutes
        self.acDisplaySleepMinutes = acDisplaySleepMinutes
        self.allowSystemSleep = allowSystemSleep
        self.allowLidAwake = allowLidAwake
        self.duration = duration
        self.lowBatteryCutoff = lowBatteryCutoff
    }

    public static let builtIns: [PowerPreset] = [
        PowerPreset(name: "正常模式", batteryDisplaySleepMinutes: 15, acDisplaySleepMinutes: 30, allowSystemSleep: true, allowLidAwake: false, duration: .infinite),
        PowerPreset(name: "长任务模式", batteryDisplaySleepMinutes: 10, acDisplaySleepMinutes: 20, allowSystemSleep: false, allowLidAwake: false, duration: .minutes(120)),
        PowerPreset(name: "合盖任务模式", batteryDisplaySleepMinutes: 3, acDisplaySleepMinutes: 10, allowSystemSleep: false, allowLidAwake: true, duration: .minutes(60))
    ]
}
