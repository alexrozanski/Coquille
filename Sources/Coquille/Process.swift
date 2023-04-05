import Foundation

public class Process {
    public typealias OutputHandler = (String) -> Void

    public enum Status {
        case success
        case failure(_ code: Int32)

        public var isSuccess: Bool {
            switch self {
            case .success: return true
            case .failure: return false
            }
        }

        public var isFailure: Bool {
            switch self {
            case .success: return false
            case .failure: return true
            }
        }

        public var errorCode: Int32? {
            switch self {
            case .success: return nil
            case .failure(let errorCode): return errorCode
            }
        }
    }

    public struct Command {
        public let name: String
        public let arguments: [String]

        public init(_ name: String, arguments: [String]) {
            self.name = name
            self.arguments = arguments
        }
    }

    public enum Output {
        case stdout
        case stderr
        case handler(OutputHandler)
    }

    let arguments: [String]

    public let stdout: Output?
    public let stderr: Output?

    // MARK: - Initializers

    public init(command: Command) {
        self.arguments = [command.name] + command.arguments
        self.stdout = .stdout
        self.stderr = .stderr
    }

    public init(command: Command, printStdout: Bool = true, printStderr: Bool = true) {
        self.arguments = [command.name] + command.arguments
        self.stdout = printStdout ? .stdout : nil
        self.stderr = printStderr ? .stderr : nil
    }

    public init(command: Command, stdout: OutputHandler? = nil) {
        self.arguments = [command.name] + command.arguments
        self.stdout = stdout.map { .handler($0) }
        self.stderr = nil
    }

    public init(command: Command, stdout: OutputHandler? = nil, stderr: OutputHandler? = nil) {
        self.arguments = [command.name] + command.arguments
        self.stdout = stdout.map { .handler($0) }
        self.stderr = stderr.map { .handler($0) }
    }

    // MARK: - Convenience Initializers

    public init(commandString: String) {
        self.arguments = commandString.components(separatedBy: " ")
        self.stdout = .stdout
        self.stderr = .stderr
    }

    public init(commandString: String, printStdout: Bool = true, printStderr: Bool = true) {
        self.arguments = commandString.components(separatedBy: " ")
        self.stdout = printStdout ? .stdout : nil
        self.stderr = printStderr ? .stderr : nil
    }

    public init(commandString: String, stdout: OutputHandler? = nil) {
        self.arguments = commandString.components(separatedBy: " ")
        self.stdout = stdout.map { .handler($0) }
        self.stderr = nil
    }

    public init(commandString: String, stdout: OutputHandler? = nil, stderr: OutputHandler? = nil) {
        self.arguments = commandString.components(separatedBy: " ")
        self.stdout = stdout.map { .handler($0) }
        self.stderr = stderr.map { .handler($0) }
    }

    // MARK: - Running tasks

    public func run() async throws -> Status {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try _run { status in
                    continuation.resume(returning: status)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func _run(with completionHandler: (Status) -> Void) throws {
        let _process = Foundation.Process()
        _process.launchPath = "/usr/bin/env"
        _process.arguments = arguments

        let stdoutPipe = Pipe()
        _process.standardOutput = stdoutPipe
        let stderrPipe = Pipe()
        _process.standardError = stderrPipe

        stdoutPipe.output(to: stdout)
        stderrPipe.output(to: stderr)

        try _process.run()
        _process.waitUntilExit()

        let exitStatus = _process.terminationStatus
        if exitStatus == 0 {
            completionHandler(.success)
        } else {
            completionHandler(.failure(exitStatus))
        }
    }
}

extension Pipe {
    fileprivate func output(to output: Coquille.Process.Output?) {
        guard let output else { return }

        fileHandleForReading.readabilityHandler = { pipe in
            switch output {
            case .stdout:
                if #available(macOS 11, *) {
                    try? FileHandle.standardOutput.write(contentsOf: pipe.availableData)
                } else {
                    FileHandle.standardOutput.write(pipe.availableData)
                }
            case .stderr:
                if #available(macOS 11, *) {
                    try? FileHandle.standardError.write(contentsOf: pipe.availableData)
                } else {
                    FileHandle.standardError.write(pipe.availableData)
                }
            case .handler(let handler):
                // This closure is called frequently with empty data, so only pass this on if we have something.
                if let string = String(data: pipe.availableData, encoding: .utf8), !string.isEmpty {
                    handler(string)
                }
            }
        }
    }
}
