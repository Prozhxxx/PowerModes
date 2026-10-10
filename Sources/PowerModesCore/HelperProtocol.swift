import Foundation

public enum HelperProtocolError: Error, Equatable, Sendable {
    case invalidArguments
}

public enum HelperRequest: Equatable, Sendable {
    case version
    case apply(batteryMinutes: Int, acMinutes: Int, allowSystemSleep: Bool, allowLidAwake: Bool)
    case cleanup(pid: Int)

    public static func parse(_ arguments: [String]) throws -> HelperRequest {
        if arguments == ["--version"] { return .version }

        if arguments.count == 2, arguments[0] == "cleanup",
           let pid = Int(arguments[1]), pid > 0 {
            return .cleanup(pid: pid)
        }

        guard arguments.count == 5, arguments[0] == "apply",
              let battery = Int(arguments[1]), (0...480).contains(battery),
              let ac = Int(arguments[2]), (0...480).contains(ac),
              let systemSleep = parseBoolean(arguments[3]),
              let lidAwake = parseBoolean(arguments[4]) else {
            throw HelperProtocolError.invalidArguments
        }
        return .apply(
            batteryMinutes: battery,
            acMinutes: ac,
            allowSystemSleep: systemSleep,
            allowLidAwake: lidAwake
        )
    }

    public func pmsetCommands() throws -> [[String]] {
        guard case let .apply(battery, ac, systemSleep, lidAwake) = self else {
            throw HelperProtocolError.invalidArguments
        }
        let sleep = systemSleep ? "1" : "0"
        return [
            ["/usr/bin/pmset", "-b", "displaysleep", String(battery), "sleep", sleep],
            ["/usr/bin/pmset", "-c", "displaysleep", String(ac), "sleep", sleep],
            ["/usr/bin/pmset", "-a", "disablesleep", lidAwake ? "1" : "0"]
        ]
    }

    private static func parseBoolean(_ value: String) -> Bool? {
        switch value {
        case "0": false
        case "1": true
        default: nil
        }
    }
}
