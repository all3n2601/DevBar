import Foundation

/// Sequential stdio dispatch keeps stdout clean and avoids UI/main-thread dependencies.
public final class MCPServer {
    private let service = DeviceService()
    public init() {}
    private let commands = [
        ("devbar_list_devices", "List available mobile devices", [String]()),
        ("devbar_doctor", "Check installed mobile development tools", [String]()),
        ("devbar_boot_device", "Boot a virtual device and wait for readiness", ["id"]),
        ("devbar_shutdown_device", "Shut down a virtual device", ["id"]),
        ("devbar_take_screenshot", "Save a PNG and return its absolute path", ["id"]),
        ("devbar_install_app", "Install a simulator .app or Android .apk", ["id", "path"]),
        ("devbar_launch_app", "Launch an installed application", ["id", "app"]),
        ("devbar_open_url", "Open a deep link on one device", ["id", "url"]),
        ("devbar_set_location", "Set GPS on one virtual device", ["id", "latitude", "longitude"])
    ]

    public func response(to data: Data) -> [String: Any]? {
        let object: Any
        do { object = try JSONSerialization.jsonObject(with: data) }
        catch { return failure(nil, -32700, "Parse error") }
        guard let request = object as? [String: Any], request["jsonrpc"] as? String == "2.0",
              let method = request["method"] as? String else { return failure(nil, -32600, "Invalid request") }
        let id = request["id"]
        if let id = id {
            if id is NSNull || (id is NSNumber && CFGetTypeID(id as CFTypeRef) == CFBooleanGetTypeID()) || !(id is String || id is NSNumber) {
                return failure(nil, -32600, "Invalid request ID")
            }
        }
        guard let id = id else { return nil } // Notifications must never receive a response.
        if request["params"] != nil && !(request["params"] is [String: Any]) { return failure(id, -32602, "Params must be an object") }
        let params = request["params"] as? [String: Any] ?? [:]
        switch method {
        case "initialize":
            let supported = ["2024-11-05", "2025-03-26", "2025-06-18"]
            let requested = params["protocolVersion"] as? String ?? ""
            return success(id, ["protocolVersion": supported.contains(requested) ? requested : "2025-06-18",
                                "capabilities": ["tools": [:]], "serverInfo": ["name": "DevBar", "version": DevBarVersion.current]])
        case "ping": return success(id, [:])
        case "tools/list":
            return success(id, ["tools": commands.map { name, description, required in
                var properties: [String: Any] = [:]
                for key in required { properties[key] = ["type": key == "latitude" || key == "longitude" ? "number" : "string"] }
                return ["name": name, "description": description,
                        "inputSchema": ["type": "object", "properties": properties, "required": required, "additionalProperties": false]] as [String: Any]
            }])
        case "tools/call":
            guard let name = params["name"] as? String, let definition = commands.first(where: { $0.0 == name }) else { return failure(id, -32602, "Unknown or missing tool name") }
            if params["arguments"] != nil && !(params["arguments"] is [String: Any]) { return failure(id, -32602, "Arguments must be an object") }
            let args = params["arguments"] as? [String: Any] ?? [:]
            for key in definition.2 {
                if key == "latitude" || key == "longitude" {
                    guard let value = args[key] as? NSNumber, CFGetTypeID(value) != CFBooleanGetTypeID() else { return failure(id, -32602, "\(key) must be a number") }
                } else if !(args[key] is String) || (args[key] as? String)?.isEmpty == true { return failure(id, -32602, "\(key) must be a nonempty string") }
            }
            guard Set(args.keys).isSubset(of: Set(definition.2)) else { return failure(id, -32602, "Unexpected tool argument") }
            do {
                var text = "Completed \(name)."
                if name == "devbar_list_devices" { text = String(decoding: try JSONEncoder().encode(service.devices()), as: UTF8.self) }
                else if name == "devbar_doctor" { text = String(decoding: try JSONSerialization.data(withJSONObject: service.doctor()), as: UTF8.self) }
                else {
                    if name == "devbar_set_location" { try DeviceService.validateLocation((args["latitude"] as! NSNumber).doubleValue, (args["longitude"] as! NSNumber).doubleValue) }
                    let device = try DeviceService.resolve(args["id"] as! String, in: service.devices())
                    switch name {
                    case "devbar_boot_device": try service.boot(device)
                    case "devbar_shutdown_device": try service.shutdown(device)
                    case "devbar_take_screenshot": text = try service.screenshot(device, path: FileManager.default.temporaryDirectory.appendingPathComponent("DevBar-\(UUID().uuidString).png").path)
                    case "devbar_install_app": try service.install(device, path: args["path"] as! String)
                    case "devbar_launch_app": try service.launch(device, app: args["app"] as! String)
                    case "devbar_open_url": try service.openURL(device, url: args["url"] as! String)
                    case "devbar_set_location": try service.location(device, latitude: (args["latitude"] as! NSNumber).doubleValue, longitude: (args["longitude"] as! NSNumber).doubleValue)
                    default: break
                    }
                }
                return success(id, ["content": [["type": "text", "text": text]], "isError": false])
            } catch { return success(id, ["content": [["type": "text", "text": error.localizedDescription]], "isError": true]) }
        default: return failure(id, -32601, "Method not found")
        }
    }

    private func success(_ id: Any, _ result: [String: Any]) -> [String: Any] { ["jsonrpc": "2.0", "id": id, "result": result] }
    private func failure(_ id: Any?, _ code: Int, _ message: String) -> [String: Any] { ["jsonrpc": "2.0", "id": id ?? NSNull(), "error": ["code": code, "message": message]] }
}
