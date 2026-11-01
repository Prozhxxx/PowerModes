import Foundation

public enum SessionAuthorizationError: LocalizedError, Equatable, Sendable {
    case invalidIdentity
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidIdentity: "无法安全创建本次授权会话"
        case .commandFailed(let message): message.isEmpty ? "本次授权失败" : message
        }
    }
}

public enum SessionAuthorizationBuilder {
    public static let helperPath = "/Library/PrivilegedHelperTools/io.z.powermodes.helper"

    public static func sudoersPath(pid: Int) -> String {
        "/private/etc/sudoers.d/io-z-powermodes-session-\(pid)"
    }

    public static func applyArguments(for preset: PowerPreset) throws -> [String] {
        _ = try PowerCommandBuilder.commands(for: preset)
        return [
            "-n", helperPath, "apply",
            String(preset.batteryDisplaySleepMinutes),
            String(preset.acDisplaySleepMinutes),
            preset.allowSystemSleep ? "1" : "0",
            preset.allowLidAwake ? "1" : "0"
        ]
    }

    public static func cleanupArguments(pid: Int) -> [String] {
        ["-n", helperPath, "cleanup", String(pid)]
    }

    public static func installCommand(helperSource: String, user: String, pid: Int) throws -> String {
        guard pid > 0,
              helperSource.hasPrefix("/"),
              !helperSource.contains("\n"),
              !helperSource.contains("\0"),
              user.range(of: "^[A-Za-z_][A-Za-z0-9_-]*$", options: .regularExpression) != nil else {
            throw SessionAuthorizationError.invalidIdentity
        }

        let sessionPath = sudoersPath(pid: pid)
        let pendingPath = sessionPath + ".new"
        let sudoersLine = "\(user) ALL=(root) NOPASSWD: \(helperPath)"
        let watcher = "while /bin/kill -0 \(pid) 2>/dev/null; do /bin/sleep 1; done; /bin/rm -f \(shellQuote(sessionPath))"

        return [
            "/usr/bin/install -d -o root -g wheel -m 0755 /Library/PrivilegedHelperTools",
            "/usr/bin/install -o root -g wheel -m 0755 \(shellQuote(helperSource)) \(shellQuote(helperPath))",
            "/usr/bin/printf '%s\\n' \(shellQuote(sudoersLine)) > \(shellQuote(pendingPath))",
            "/bin/chmod 0440 \(shellQuote(pendingPath))",
            "/usr/sbin/visudo -cf \(shellQuote(pendingPath))",
            "/bin/mv -f \(shellQuote(pendingPath)) \(shellQuote(sessionPath))",
            "/usr/bin/nohup /bin/sh -c \(shellQuote(watcher)) >/dev/null 2>&1 </dev/null &"
        ].joined(separator: "; ")
    }

    private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
