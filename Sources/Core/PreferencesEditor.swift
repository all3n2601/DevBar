import Foundation

/// Preserve other keys and the existing value type; never synthesize a file after a failed read.
public enum PreferencesEditor {
    public static func validateBundleID(_ id: String) throws {
        guard id.range(of: "^[A-Za-z0-9_-]+(\\.[A-Za-z0-9_-]+)+$", options: .regularExpression) != nil else {
            throw DevBarError("Supply a valid bundle ID or package name.")
        }
    }

    public static func propertyList(_ data: Data, key: String, value: String) throws -> Data {
        guard var values = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw DevBarError("Preferences must be a dictionary.")
        }
        if let old = values[key] {
            if let number = old as? NSNumber {
                if CFGetTypeID(number) == CFBooleanGetTypeID() {
                    guard value == "true" || value == "false" else { throw DevBarError("Boolean values must be true or false.") }
                    values[key] = value == "true"
                } else if String(cString: number.objCType) == "d" || String(cString: number.objCType) == "f" {
                    guard let parsed = Double(value), parsed.isFinite else { throw DevBarError("Expected a finite number.") }
                    values[key] = parsed
                } else {
                    guard let parsed = Int64(value) else { throw DevBarError("Expected an integer.") }
                    values[key] = parsed
                }
            } else if old is String { values[key] = value }
            else { throw DevBarError("Editing collection, date, and binary preferences is unsupported.") }
        } else { values[key] = value }
        return try PropertyListSerialization.data(fromPropertyList: values, format: .binary, options: 0)
    }

    public static func androidXML(_ data: Data, key: String, value: String) throws -> Data {
        guard let source = String(data: data, encoding: .utf8), !source.uppercased().contains("<!DOCTYPE") else {
            throw DevBarError("Invalid preference XML or unsupported DOCTYPE.")
        }
        let document = try XMLDocument(xmlString: source, options: [.nodePreserveAll])
        guard let root = document.rootElement(), root.name == "map" else { throw DevBarError("Expected a SharedPreferences map.") }
        let matches = (root.children ?? []).compactMap { $0 as? XMLElement }.filter { $0.attribute(forName: "name")?.stringValue == key }
        guard matches.count <= 1 else { throw DevBarError("Duplicate preference key.") }
        if let existing = matches.first {
            switch existing.name {
            case "string": existing.stringValue = value
            case "boolean":
                guard value == "true" || value == "false" else { throw DevBarError("Boolean values must be true or false.") }
                existing.attribute(forName: "value")?.stringValue = value
            case "int", "long":
                guard let parsed = Int64(value), existing.name != "int" || Int32(exactly: parsed) != nil else { throw DevBarError("Integer out of range.") }
                existing.attribute(forName: "value")?.stringValue = value
            case "float":
                guard let parsed = Float(value), parsed.isFinite else { throw DevBarError("Expected a finite float.") }
                existing.attribute(forName: "value")?.stringValue = value
            default: throw DevBarError("Editing this preference type is unsupported.")
            }
        } else {
            let element = XMLElement(name: "string", stringValue: value)
            element.addAttribute(XMLNode.attribute(withName: "name", stringValue: key) as! XMLNode)
            root.addChild(element)
        }
        return document.xmlData
    }
}
