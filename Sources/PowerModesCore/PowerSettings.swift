import Foundation

public struct PowerProfile: Equatable, Sendable {
    public var displaySleepMinutes: Int
    public var systemSleepEnabled: Bool

    public init(displaySleepMinutes: Int, systemSleepEnabled: Bool) {
        self.displaySleepMinutes = displaySleepMinutes
        self.systemSleepEnabled = systemSleepEnabled
    }
}

public struct VerificationResult: Equatable, Sendable {
    public var isVerified: Bool { mismatches.isEmpty }
    public let mismatches: [String]
}

public struct PowerSettingsSnapshot: Equatable, Sendable {
    public var battery: PowerProfile
    public var ac: PowerProfile
    public var lidSleepDisabled: Bool
    public var sourceDescription: String

    public init(battery: PowerProfile, ac: PowerProfile, lidSleepDisabled: Bool, sourceDescription: String) {
        self.battery = battery
        self.ac = ac
        self.lidSleepDisabled = lidSleepDisabled
        self.sourceDescription = sourceDescription
    }

    public func verify(against preset: PowerPreset) -> VerificationResult {
        var mismatches: [String] = []
        if battery.displaySleepMinutes != preset.batteryDisplaySleepMinutes { mismatches.append("电池关屏时间") }
        if ac.displaySleepMinutes != preset.acDisplaySleepMinutes { mismatches.append("插电关屏时间") }
        if battery.systemSleepEnabled != preset.allowSystemSleep || ac.systemSleepEnabled != preset.allowSystemSleep { mismatches.append("系统睡眠") }
        if lidSleepDisabled != preset.allowLidAwake { mismatches.append("合盖行为") }
        return VerificationResult(mismatches: mismatches)
    }
}

public enum PowerModesError: Error, Equatable, LocalizedError {
    case invalidMinutes
    case invalidBatteryCutoff
    case parseFailed
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidMinutes: "关屏时间必须在 0 到 480 分钟之间"
        case .invalidBatteryCutoff: "低电量阈值必须在 5% 到 80% 之间"
        case .parseFailed: "无法读取 macOS 电源配置"
        case .commandFailed(let message): "应用失败：\(message)"
        }
    }
}
