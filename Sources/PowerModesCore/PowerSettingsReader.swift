import Foundation

public enum PowerSettingsParser {
    public static func parse(_ text: String) throws -> PowerSettingsSnapshot {
        enum Section { case none, battery, ac, global }
        var section = Section.none
        var batteryDisplay: Int?
        var batterySleep: Int?
        var acDisplay: Int?
        var acSleep: Int?
        var sleepDisabled = false
        var source = "未知"

        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line == "Battery Power:" { section = .battery; continue }
            if line == "AC Power:" { section = .ac; continue }
            if line == "System-wide power settings:" { section = .global; continue }
            if line.hasPrefix("Now drawing from '") {
                source = line.replacingOccurrences(of: "Now drawing from '", with: "").replacingOccurrences(of: "'", with: "")
                continue
            }
            let parts = line.split(whereSeparator: { $0.isWhitespace })
            guard parts.count >= 2, let value = Int(parts.last!) else { continue }
            let key = parts.dropLast().joined(separator: " ").lowercased()
            switch (section, key) {
            case (.battery, "displaysleep"): batteryDisplay = value
            case (.battery, "sleep"): batterySleep = value
            case (.ac, "displaysleep"): acDisplay = value
            case (.ac, "sleep"): acSleep = value
            case (.global, "sleepdisabled"): sleepDisabled = value == 1
            default: break
            }
        }
        guard let bd = batteryDisplay, let bs = batterySleep, let ad = acDisplay, let `as` = acSleep else {
            throw PowerModesError.parseFailed
        }
        return PowerSettingsSnapshot(
            battery: PowerProfile(displaySleepMinutes: bd, systemSleepEnabled: bs != 0),
            ac: PowerProfile(displaySleepMinutes: ad, systemSleepEnabled: `as` != 0),
            lidSleepDisabled: sleepDisabled,
            sourceDescription: source
        )
    }

    public static func parsePlist(_ data: Data, globalText: String, batteryText: String) throws -> PowerSettingsSnapshot {
        guard let root = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let battery = root["Battery Power"] as? [String: Any],
              let ac = root["AC Power"] as? [String: Any],
              let bd = battery["Display Sleep Timer"] as? Int,
              let bs = battery["System Sleep Timer"] as? Int,
              let ad = ac["Display Sleep Timer"] as? Int,
              let acs = ac["System Sleep Timer"] as? Int else {
            throw PowerModesError.parseFailed
        }
        let disabled = globalText.split(separator: "\n").contains { line in
            let parts = line.split(whereSeparator: { $0.isWhitespace })
            return parts.count >= 2 && parts.first?.lowercased() == "sleepdisabled" && parts.last == "1"
        }
        let sourceLine = batteryText.split(separator: "\n").first { $0.contains("Now drawing from '") }
        let source = sourceLine.map(String.init)?
            .replacingOccurrences(of: "Now drawing from '", with: "")
            .replacingOccurrences(of: "'", with: "")
            .trimmingCharacters(in: .whitespaces) ?? "未知"
        return PowerSettingsSnapshot(
            battery: .init(displaySleepMinutes: bd, systemSleepEnabled: bs != 0),
            ac: .init(displaySleepMinutes: ad, systemSleepEnabled: acs != 0),
            lidSleepDisabled: disabled,
            sourceDescription: source
        )
    }
}

public struct PowerSettingsReader: Sendable {
    public init() {}

    public func read() throws -> PowerSettingsSnapshot {
        let custom = try run(["-g", "custom"])
        let global = try run(["-g"])
        let battery = try run(["-g", "batt"])
        do {
            return try PowerSettingsParser.parse(custom + "\n" + global + "\n" + battery)
        } catch PowerModesError.parseFailed {
            let plistURL = URL(fileURLWithPath: "/Library/Preferences/com.apple.PowerManagement.plist")
            return try PowerSettingsParser.parsePlist(Data(contentsOf: plistURL), globalText: global, batteryText: battery)
        }
    }

    private func run(_ arguments: [String]) throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        guard process.terminationStatus == 0 else { throw PowerModesError.commandFailed(output) }
        return output
    }
}
