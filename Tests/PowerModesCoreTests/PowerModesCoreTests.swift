import Foundation
import Testing
@testable import PowerModesCore

@Test func builtInPresetsCoverNormalAndTaskModes() {
    let presets = PowerPreset.builtIns
    #expect(presets.map(\.name) == ["正常模式", "长任务模式", "合盖任务模式"])
    #expect(presets[0].allowLidAwake == false)
    #expect(presets[0].batteryDisplaySleepMinutes == 15)
    #expect(presets[0].acDisplaySleepMinutes == 30)
    #expect(presets[1].batteryDisplaySleepMinutes == 10)
    #expect(presets[1].acDisplaySleepMinutes == 20)
    #expect(presets[2].batteryDisplaySleepMinutes == 3)
    #expect(presets[2].acDisplaySleepMinutes == 10)
    #expect(presets[2].allowLidAwake == true)
}

@Test func helperProtocolParsesOnlySupportedApplyArguments() throws {
    let request = try HelperRequest.parse(["apply", "10", "20", "1", "0"])
    #expect(request == .apply(batteryMinutes: 10, acMinutes: 20, allowSystemSleep: true, allowLidAwake: false))
    #expect(try request.pmsetCommands() == [
        ["/usr/bin/pmset", "-b", "displaysleep", "10", "sleep", "1"],
        ["/usr/bin/pmset", "-c", "displaysleep", "20", "sleep", "1"],
        ["/usr/bin/pmset", "-a", "disablesleep", "0"]
    ])
}

@Test func helperProtocolRejectsInjectedAndOutOfRangeArguments() {
    #expect(throws: HelperProtocolError.self) {
        try HelperRequest.parse(["apply", "10;touch /tmp/x", "20", "1", "0"])
    }
    #expect(throws: HelperProtocolError.self) {
        try HelperRequest.parse(["apply", "481", "20", "1", "0"])
    }
    #expect(throws: HelperProtocolError.self) {
        try HelperRequest.parse(["cleanup", "-1"])
    }
}

@Test func presetStoreMigratesNormalAndLongTaskTimesOnce() throws {
    let suite = "PowerModesMigrationTests-\(UUID())"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = PresetStore(defaults: defaults)
    var legacy = PowerPreset.builtIns
    legacy[0].batteryDisplaySleepMinutes = 7
    legacy[0].acDisplaySleepMinutes = 5
    legacy[1].batteryDisplaySleepMinutes = 5
    legacy[1].acDisplaySleepMinutes = 5
    try store.save(legacy)

    let migrated = try store.load()
    #expect(migrated[0].batteryDisplaySleepMinutes == 15)
    #expect(migrated[0].acDisplaySleepMinutes == 30)
    #expect(migrated[1].batteryDisplaySleepMinutes == 10)
    #expect(migrated[1].acDisplaySleepMinutes == 20)
    #expect(migrated[2].batteryDisplaySleepMinutes == 3)
    #expect(migrated[2].acDisplaySleepMinutes == 10)

    var customized = migrated
    customized[0].acDisplaySleepMinutes = 30
    try store.save(customized)
    #expect(try store.load()[0].acDisplaySleepMinutes == 30)
}

@Test func sessionAuthorizationBuildsPasswordFreeHelperInvocation() throws {
    let preset = PowerPreset.builtIns[0]
    #expect(try SessionAuthorizationBuilder.applyArguments(for: preset) == [
        "-n", "/Library/PrivilegedHelperTools/io.z.powermodes.helper",
        "apply", "15", "30", "1", "0"
    ])
    #expect(SessionAuthorizationBuilder.cleanupArguments(pid: 4321) == [
        "-n", "/Library/PrivilegedHelperTools/io.z.powermodes.helper", "cleanup", "4321"
    ])
}

@Test func sessionAuthorizationInstallerIsPidScopedAndRejectsUnsafeIdentity() throws {
    let command = try SessionAuthorizationBuilder.installCommand(
        helperSource: "/Applications/电源模式.app/Contents/Helpers/PowerModesHelper",
        user: "hx",
        pid: 4321
    )
    #expect(command.contains("/Library/PrivilegedHelperTools/io.z.powermodes.helper"))
    #expect(command.contains("/private/etc/sudoers.d/io-z-powermodes-session-4321"))
    let ruleName = URL(fileURLWithPath: SessionAuthorizationBuilder.sudoersPath(pid: 4321)).lastPathComponent
    #expect(!ruleName.contains("."))
    #expect(command.contains("/usr/sbin/visudo -cf"))
    #expect(command.contains("/bin/kill -0 4321"))
    #expect(command.contains("/usr/bin/nohup"))
    #expect(throws: SessionAuthorizationError.self) {
        try SessionAuthorizationBuilder.installCommand(helperSource: "/tmp/helper", user: "hx ALL=(ALL)", pid: 1)
    }
    #expect(throws: SessionAuthorizationError.self) {
        try SessionAuthorizationBuilder.installCommand(helperSource: "relative/helper", user: "hx", pid: 1)
    }
}

@Test func presetsRoundTripThroughStore() throws {
    let suite = "PowerModesTests-\(UUID())"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let store = PresetStore(defaults: defaults)
    var preset = PowerPreset.builtIns[0]
    preset.name = "我的模式"
    try store.save([preset])
    #expect(try store.load() == [preset])
}

@Test func parsesPmsetProfilesAndGlobalSleepDisabled() throws {
    let text = """
    Battery Power:
     displaysleep         10
     sleep                1
    AC Power:
     displaysleep         5
     sleep                0
    System-wide power settings:
     SleepDisabled        1
    """
    let snapshot = try PowerSettingsParser.parse(text)
    #expect(snapshot.battery.displaySleepMinutes == 10)
    #expect(snapshot.battery.systemSleepEnabled == true)
    #expect(snapshot.ac.displaySleepMinutes == 5)
    #expect(snapshot.ac.systemSleepEnabled == false)
    #expect(snapshot.lidSleepDisabled == true)
}

@Test func parsesProfilesFromSystemPlistWhenPmsetOmitsBatterySection() throws {
    let plist: [String: Any] = [
        "Battery Power": ["Display Sleep Timer": 10, "System Sleep Timer": 1],
        "AC Power": ["Display Sleep Timer": 5, "System Sleep Timer": 1]
    ]
    let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    let snapshot = try PowerSettingsParser.parsePlist(
        data,
        globalText: "System-wide power settings:\n SleepDisabled 0",
        batteryText: "Now drawing from 'AC Power'"
    )
    #expect(snapshot.battery.displaySleepMinutes == 10)
    #expect(snapshot.ac.displaySleepMinutes == 5)
    #expect(snapshot.sourceDescription == "AC Power")
}

@Test func commandBuilderUsesOnlyValidatedNumericValues() throws {
    var preset = PowerPreset.builtIns[0]
    preset.name = "bad; touch /tmp/pwned"
    preset.batteryDisplaySleepMinutes = 12
    preset.acDisplaySleepMinutes = 8
    let commands = try PowerCommandBuilder.commands(for: preset)
    #expect(commands == [
        ["pmset", "-b", "displaysleep", "12", "sleep", "1"],
        ["pmset", "-c", "displaysleep", "8", "sleep", "1"],
        ["pmset", "-a", "disablesleep", "0"]
    ])
    #expect(commands.flatMap { $0 }.contains(where: { $0.contains("touch") }) == false)
}

@Test func commandBuilderRejectsOutOfRangeMinutes() {
    var preset = PowerPreset.builtIns[0]
    preset.batteryDisplaySleepMinutes = 999
    #expect(throws: PowerModesError.invalidMinutes) {
        try PowerCommandBuilder.commands(for: preset)
    }
}

@Test func verificationExplainsMismatch() {
    let expected = PowerPreset.builtIns[0]
    let actual = PowerSettingsSnapshot(
        battery: .init(displaySleepMinutes: 9, systemSleepEnabled: true),
        ac: .init(displaySleepMinutes: 5, systemSleepEnabled: true),
        lidSleepDisabled: false,
        sourceDescription: "Battery Power"
    )
    let result = actual.verify(against: expected)
    #expect(result.isVerified == false)
    #expect(result.mismatches.contains("电池关屏时间"))
}
