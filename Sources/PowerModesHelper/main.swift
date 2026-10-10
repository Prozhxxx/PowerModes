import Darwin
import Foundation
import PowerModesCore

private func fail(_ message: String, code: Int32 = 2) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

private func run(_ command: [String]) throws {
    guard let executable = command.first else { throw HelperProtocolError.invalidArguments }
    let process = Process()
    let output = Pipe()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = Array(command.dropFirst())
    process.standardOutput = output
    process.standardError = output
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        let message = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        throw SessionAuthorizationError.commandFailed(message.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

do {
    let request = try HelperRequest.parse(Array(CommandLine.arguments.dropFirst()))
    if request == .version {
        print("1")
        exit(0)
    }
    guard geteuid() == 0 else { fail("helper must run as root", code: 77) }

    switch request {
    case .version:
        break
    case .apply:
        for command in try request.pmsetCommands() { try run(command) }
    case .cleanup(let pid):
        let path = SessionAuthorizationBuilder.sudoersPath(pid: pid)
        try? FileManager.default.removeItem(atPath: path + ".new")
        try FileManager.default.removeItem(atPath: path)
    }
} catch {
    fail(error.localizedDescription)
}
