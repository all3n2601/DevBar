import Foundation

public struct ShellResult {
    public init(status: Int32, output: String = "", error: String = "") {
        self.status = status; self.output = output; self.error = error
    }
    public let status: Int32
    public let output: String
    public let error: String
}

public class Shell {
    public static let shared = Shell()

    private init() {}

    /// Resolves the absolute path for the Android SDK root directory.
    public func resolveAndroidSdkPath() -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let standardPath = "\(home)/Library/Android/sdk"


        // Check environment variable
        if let sdkEnv = ProcessInfo.processInfo.environment["ANDROID_SDK_ROOT"],
           FileManager.default.fileExists(atPath: sdkEnv) {
            return sdkEnv
        }
        if let homeEnv = ProcessInfo.processInfo.environment["ANDROID_HOME"],
           FileManager.default.fileExists(atPath: homeEnv) {
            return homeEnv
        }

        return FileManager.default.fileExists(atPath: standardPath) ? standardPath : nil
    }

    /// Resolves and caches the path to the adb binary.
    public func resolveAdbPath() -> String {

        // 1. Check standard SDK path
        if let sdkPath = resolveAndroidSdkPath() {
            let adbSdkPath = "\(sdkPath)/platform-tools/adb"
            if FileManager.default.fileExists(atPath: adbSdkPath) {
                return adbSdkPath
            }
        }

        // 2. Check common homebrew paths
        let homebrewPaths = [
            "/opt/homebrew/bin/adb",
            "/usr/local/bin/adb"
        ]
        for path in homebrewPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // 3. Fallback to raw command (assumes it is in system environment PATH)
        return "adb"
    }

    /// Resolves and caches the path to the emulator binary.
    public func resolveEmulatorPath() -> String {

        // 1. Check standard SDK path
        if let sdkPath = resolveAndroidSdkPath() {
            let emulatorSdkPath = "\(sdkPath)/emulator/emulator"
            if FileManager.default.fileExists(atPath: emulatorSdkPath) {
                return emulatorSdkPath
            }
        }

        // 2. Check common homebrew paths
        let homebrewPaths = [
            "/opt/homebrew/bin/emulator",
            "/usr/local/bin/emulator"
        ]
        for path in homebrewPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // 3. Fallback to raw command
        return "emulator"
    }

    /// Runs a process synchronously and returns the output results.
    @discardableResult
    public func run(executable: String, arguments: [String], timeout: TimeInterval = 30) -> ShellResult {
        // File-backed output avoids pipe buffer deadlocks, including child processes
        // that inherit stdout/stderr. Binary output is handled by device-side files.
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let out = directory.appendingPathComponent("stdout")
            let err = directory.appendingPathComponent("stderr")
            FileManager.default.createFile(atPath: out.path, contents: nil)
            FileManager.default.createFile(atPath: err.path, contents: nil)
            let outHandle = try FileHandle(forWritingTo: out)
            let errHandle = try FileHandle(forWritingTo: err)
            defer { try? outHandle.close(); try? errHandle.close() }
            let process = Process()
            process.standardInput = FileHandle.nullDevice
            process.standardOutput = outHandle
            process.standardError = errHandle
            process.executableURL = URL(fileURLWithPath: executable.hasPrefix("/") ? executable : findBinary(executable) ?? executable)
            process.arguments = arguments
            try process.run()
            let deadline = Date().addingTimeInterval(timeout)
            while process.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.02) }
            let timedOut = process.isRunning
            if timedOut {
                process.terminate()
                let grace = Date().addingTimeInterval(1)
                while process.isRunning && Date() < grace { Thread.sleep(forTimeInterval: 0.02) }
                if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            }
            process.waitUntilExit()
            let output = String(decoding: try Data(contentsOf: out), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            let error = String(decoding: try Data(contentsOf: err), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            return ShellResult(status: timedOut ? 124 : process.terminationStatus, output: output,
                               error: timedOut ? "Command timed out after \(timeout)s. \(error)" : error)
        } catch {
            return ShellResult(status: -1, output: "", error: error.localizedDescription)
        }
    }

    /// Runs a command in the background asynchronously. Useful for booting emulators.
    public func runAsync(executable: String, arguments: [String], completion: @escaping (ShellResult) -> Void = { _ in }) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.run(executable: executable, arguments: arguments)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    /// Spawns a background process asynchronously and returns it for tracking and termination.
    public func runAsynchronousProcess(executable: String, arguments: [String]) -> Process? {
        let process = Process()
        process.standardOutput = FileHandle.standardError
        process.standardError = FileHandle.standardError
        process.standardInput = FileHandle.nullDevice
        process.arguments = arguments
        process.executableURL = URL(fileURLWithPath: executable.hasPrefix("/") ? executable : findBinary(executable) ?? executable)

        var env = ProcessInfo.processInfo.environment
        if let sdkPath = resolveAndroidSdkPath() {
            let pathValue = env["PATH"] ?? ""
            env["PATH"] = "\(sdkPath)/platform-tools:\(sdkPath)/emulator:\(pathValue)"
        }
        process.environment = env

        do {
            try process.run()
            return process
        } catch {
            FileHandle.standardError.write(Data("Failed to start async process \(executable): \(error)\n".utf8))
            return nil
        }
    }

    /// Internal helper to locate a binary using `/usr/bin/which`.
    private func findBinary(_ name: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = nil
        process.arguments = [name]
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                return path
            }
        } catch {}
        return nil
    }
}
