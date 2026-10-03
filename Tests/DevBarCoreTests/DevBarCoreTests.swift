import XCTest
@testable import DevBarCore

final class DevBarCoreTests: XCTestCase {
    private func device(_ id: String = "test", name: String = "Phone", platform: DevicePlatform = .ios, state: DeviceState = .booted, physical: Bool = false) -> Device {
        Device(id: id, name: name, platform: platform, state: state, osVersion: "18.0", isPhysical: physical)
    }

    func testLargeOutputCannotDeadlock() {
        let result = Shell.shared.run(executable: "/bin/sh", arguments: ["-c", "dd if=/dev/zero bs=65536 count=8 2>/dev/null; dd if=/dev/zero bs=65536 count=8 1>&2 2>/dev/null"], timeout: 5)
        XCTAssertEqual(result.status, 0)
        XCTAssertEqual(result.output.utf8.count, 524288)
        XCTAssertEqual(result.error.utf8.count, 524288)
    }

    func testTimeoutAndNonzeroStatus() {
        let start = Date()
        let result = Shell.shared.run(executable: "/bin/sleep", arguments: ["10"], timeout: 0.1)
        XCTAssertEqual(result.status, 124)
        XCTAssertLessThan(Date().timeIntervalSince(start), 3)
        let failure = Shell.shared.run(executable: "/bin/sh", arguments: ["-c", "echo failure >&2; exit 7"])
        XCTAssertEqual(failure.status, 7)
        XCTAssertEqual(failure.error, "failure")
    }

    func testMissingExecutable() {
        XCTAssertNotEqual(Shell.shared.run(executable: "/nonexistent/devbar-tool", arguments: []).status, 0)
    }

    func testExactIDWinsAndAmbiguousNamesFail() throws {
        let devices = [device("a"), device("b")]
        XCTAssertEqual(try DeviceService.resolve("b", in: devices).id, "b")
        XCTAssertThrowsError(try DeviceService.resolve("Phone", in: devices))
        XCTAssertThrowsError(try DeviceService.resolve("missing", in: devices))
    }

    func testIOSDiscoveryFiltersUnavailableAndPreservesBooting() throws {
        let fixture = #"{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-18-2":[{"udid":"a","name":"Phone","state":"Booting","isAvailable":true},{"udid":"b","name":"Old","state":"Shutdown","isAvailable":false}],"com.apple.CoreSimulator.SimRuntime.tvOS-18-0":[{"udid":"c","name":"TV","state":"Booted","isAvailable":true}]}}"#
        let devices = try DeviceService.parseIosDevices(Data(fixture.utf8))
        XCTAssertEqual(devices.count, 1)
        XCTAssertEqual(devices.first?.state, .booting)
        XCTAssertEqual(devices.first?.osVersion, "18.2")
        XCTAssertThrowsError(try DeviceService.parseIosDevices(Data("invalid".utf8)))
    }

    func testAndroidDiscoveryDoesNotDuplicateRunningAVDAndIdentifiesPhysicalDevices() {
        let service = DeviceService { _, args, _ in
            if args == ["devices"] { return ShellResult(status: 0, output: "List of devices attached\nemulator-5554\tdevice\nphysical-1\tdevice\nunauthorized-1\tunauthorized") }
            if args == ["-list-avds"] { return ShellResult(status: 0, output: "Pixel_API_35\nOther_API_34") }
            if args.last == "ro.build.version.sdk" { return ShellResult(status: 0, output: "35") }
            if args.last == "ro.boot.qemu.avd_name" { return ShellResult(status: 0, output: args.contains("emulator-5554") ? "Pixel_API_35" : "") }
            return ShellResult(status: 1)
        }
        let devices = service.fetchAndroidDevices()
        XCTAssertEqual(devices.count, 3)
        XCTAssertEqual(devices.filter { $0.name == "Pixel API 35" }.count, 1)
        XCTAssertEqual(devices.first { $0.id == "physical-1" }?.isPhysical, true)
        XCTAssertEqual(devices.first { $0.id == "Other_API_34" }?.state, .shutdown)
        XCTAssertFalse(devices.contains { $0.id == "unauthorized-1" })
    }

    func testMissingSDKDiscoveryIsGraceful() {
        let service = DeviceService { _, _, _ in ShellResult(status: -1, error: "not installed") }
        XCTAssertTrue(service.devices().isEmpty)
    }

    func testLocationRejectsInvalidValuesBeforeExecuting() {
        let service = DeviceService { _, _, _ in XCTFail("Invalid coordinates must not execute commands"); return ShellResult(status: 0) }
        for pair in [(91.0, 0.0), (0.0, 181.0), (Double.nan, 0.0), (0.0, Double.infinity)] {
            XCTAssertThrowsError(try service.location(device(), latitude: pair.0, longitude: pair.1))
        }
        XCTAssertThrowsError(try service.location(device(physical: true), latitude: 0, longitude: 0))
    }

    func testLocationArgumentOrderAndSingleCoordinateForIOS() throws {
        var calls: [[String]] = []
        let service = DeviceService { _, args, _ in calls.append(args); return ShellResult(status: 0) }
        try service.location(device(), latitude: 37, longitude: -122)
        try service.location(device(platform: .android), latitude: 37, longitude: -122)
        XCTAssertEqual(calls[0], ["simctl", "location", "test", "set", "37.0,-122.0"])
        XCTAssertEqual(Array(calls[1].suffix(4)), ["geo", "fix", "-122.0", "37.0"])
    }

    func testCommandFailuresPropagateAndPhysicalShutdownIsBlocked() {
        let service = DeviceService { _, _, _ in ShellResult(status: 1, error: "tool failed") }
        XCTAssertThrowsError(try service.shutdown(device())) { XCTAssertEqual($0.localizedDescription, "tool failed") }
        XCTAssertThrowsError(try service.shutdown(device(platform: .android, physical: true)))
    }

    func testBootWaitsForIOSReadiness() throws {
        var calls: [[String]] = []
        let service = DeviceService { _, args, _ in calls.append(args); return ShellResult(status: 0) }
        try service.boot(device(state: .shutdown))
        XCTAssertEqual(calls, [["simctl", "boot", "test"], ["simctl", "bootstatus", "test", "-b"]])
    }

    func testDeepLinkRemoteQuoting() throws {
        let url = "demo://open?name=O'Brian&value=$(touch /tmp/pwned)"
        var call: [String] = []
        let service = DeviceService { _, args, _ in call = args; return ShellResult(status: 0) }
        try service.openURL(device(platform: .android), url: url)
        XCTAssertEqual(call.last, "'demo://open?name=O'\\''Brian&value=$(touch /tmp/pwned)'")
    }

    func testPreferencesKeepTypesAndUnrelatedKeys() throws {
        let original: [String: Any] = ["enabled": true, "count": 7, "name": "Allen", "other": ["keep": "this"]]
        let data = try PropertyListSerialization.data(fromPropertyList: original, format: .binary, options: 0)
        let updated = try PreferencesEditor.propertyList(data, key: "count", value: "8")
        let dict = try PropertyListSerialization.propertyList(from: updated, format: nil) as! [String: Any]
        XCTAssertEqual(dict["count"] as? Int, 8)
        XCTAssertEqual(dict["enabled"] as? Bool, true)
        XCTAssertEqual(dict["other"] as? [String: String], ["keep": "this"])
        XCTAssertThrowsError(try PreferencesEditor.propertyList(data, key: "enabled", value: "maybe"))
        XCTAssertThrowsError(try PreferencesEditor.propertyList(data, key: "other", value: "overwrite"))
        XCTAssertThrowsError(try PreferencesEditor.validateBundleID("../../escape"))
    }

    func testXMLPreferencesEditOneKeyAndEscapeSpecialCharacters() throws {
        let data = Data(#"<map><string name="name">old</string><int name="count" value="7"/><boolean name="enabled" value="true"/></map>"#.utf8)
        let updated = try PreferencesEditor.androidXML(data, key: "name", value: "A & <B>")
        let document = try XMLDocument(data: updated)
        XCTAssertEqual(try document.nodes(forXPath: "/map/string[@name='name']").first?.stringValue, "A & <B>")
        XCTAssertEqual(try document.nodes(forXPath: "/map/int[@name='count']/@value").first?.stringValue, "7")
        XCTAssertThrowsError(try PreferencesEditor.androidXML(data, key: "count", value: "not a number"))
        XCTAssertThrowsError(try PreferencesEditor.androidXML(Data("<!DOCTYPE map><map/>".utf8), key: "a", value: "b"))
    }

    private func rpc(_ text: String) -> [String: Any]? { MCPServer().response(to: Data(text.utf8)) }

    func testMCPProtocolAndNotifications() {
        let response = rpc(#"{"jsonrpc":"2.0","id":"request","method":"initialize","params":{"protocolVersion":"2024-11-05"}}"#)
        XCTAssertEqual(response?["id"] as? String, "request")
        XCTAssertEqual((response?["result"] as? [String: Any])?["protocolVersion"] as? String, "2024-11-05")
        XCTAssertNil(rpc(#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#))
        XCTAssertNil(rpc(#"{"jsonrpc":"2.0","method":"unknown"}"#))
        XCTAssertNotNil(rpc("invalid")?["error"])
        XCTAssertNotNil(rpc(#"{"jsonrpc":"1.0","id":1,"method":"ping"}"#)?["error"])
        XCTAssertNotNil(rpc(#"{"jsonrpc":"2.0","id":true,"method":"ping"}"#)?["error"])
    }

    func testMCPToolSchemaAndValidation() {
        let response = rpc(#"{"jsonrpc":"2.0","id":0,"method":"tools/list"}"#)
        let tools = (response?["result"] as? [String: Any])?["tools"] as? [[String: Any]]
        XCTAssertEqual(tools?.count, 9)
        XCTAssertNotNil(rpc(#"{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"devbar_set_location","arguments":{"id":"x","latitude":true,"longitude":0}}}"#)?["error"])
        let invalidGPS = rpc(#"{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"devbar_set_location","arguments":{"id":"x","latitude":99,"longitude":0}}}"#)
        XCTAssertEqual((invalidGPS?["result"] as? [String: Any])?["isError"] as? Bool, true)
    }
}
