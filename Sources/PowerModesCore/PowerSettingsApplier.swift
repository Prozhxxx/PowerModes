import Foundation

public struct PowerAuthorizationSession: Equatable, Sendable {
    public let pid: Int

    public init(pid: Int) { self.pid = pid }
}

public struct PowerSettingsApplier: Sendable {
    public init() {}

    public func beginSession(helperSource: String, user: String, pid: Int) throws -> PowerAuthorizationSession {
        let command = try SessionAuthorizationBuilder.installCommand(helperSource: helperSource, user: user, pid: pid)
        let appleScript = "on run argv\n do shell script (item 1 of argv) with administrator privileges\nend run"
        try run("/usr/bin/osascript", ["-e", appleScript, command])
        try run("/usr/bin/sudo", ["-n", SessionAuthorizationBuilder.helperPath, "--version"])
        return PowerAuthorizationSession(pid: pid)
    }

    public func apply(_ preset: PowerPreset, session: PowerAuthorizationSession) throws {
        guard session.pid > 0 else { throw SessionAuthorizationError.invalidIdentity }
        try run("/usr/bin/sudo", SessionAuthorizationBuilder.applyArguments(for: preset))
    }

    public func endSession(_ session: PowerAuthorizationSession) {
        try? run("/usr/bin/sudo", SessionAuthorizationBuilder.cleanupArguments(pid: session.pid))
    }

    private func run(_ executable: String, _ arguments: [String]) throws {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        guard process.terminationStatus == 0 else {
            throw SessionAuthorizationError.commandFailed(output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
