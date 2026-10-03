import Foundation
import DevBarCore

public final class MCPEngine {
    public static let shared = MCPEngine()
    private init() {}
    public func start() {
        let server = MCPServer()
        while let line = readLine() {
            guard let response = server.response(to: Data(line.utf8)),
                  let data = try? JSONSerialization.data(withJSONObject: response) else { continue }
            FileHandle.standardOutput.write(data + Data([10]))
        }
    }
}
