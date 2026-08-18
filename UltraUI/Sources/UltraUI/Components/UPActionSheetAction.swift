import CoreGraphics
import Foundation

/// Action payload for `UPActionSheet`, mirroring uview-plus action objects
/// while keeping a typed Swift surface for common fields.
public struct UPActionSheetAction: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var subname: String
    public var color: String
    public var fontSize: String
    public var disabled: Bool
    public var loading: Bool
    public var openType: String
    public var values: [String: String]

    public init(
        id: String = UUID().uuidString,
        name: String = "",
        subname: String = "",
        color: String = "",
        disabled: Bool = false,
        loading: Bool = false,
        openType: String = "",
        values: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.subname = subname
        self.color = color
        self.fontSize = ""
        self.disabled = disabled
        self.loading = loading
        self.openType = openType
        self.values = Self.mergedValues(values, name: name, subname: subname)
    }

    public init<FontSize: UPActionSheetUnitValue>(
        id: String = UUID().uuidString,
        name: String = "",
        subname: String = "",
        color: String = "",
        fontSize: FontSize,
        disabled: Bool = false,
        loading: Bool = false,
        openType: String = "",
        values: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.subname = subname
        self.color = color
        self.fontSize = fontSize.upCheckboxUnitValue
        self.disabled = disabled
        self.loading = loading
        self.openType = openType
        self.values = Self.mergedValues(values, name: name, subname: subname)
    }

    public init(id: String = UUID().uuidString, values: [String: String]) {
        self.id = id
        self.name = values["name"] ?? ""
        self.subname = values["subname"] ?? values["subnameKey"] ?? ""
        self.color = values["color"] ?? ""
        self.fontSize = values["fontSize"] ?? values["font-size"] ?? ""
        self.disabled = Self.boolValue(values["disabled"])
        self.loading = Self.boolValue(values["loading"])
        self.openType = values["openType"] ?? values["open-type"] ?? ""
        self.values = values
    }

    public func value(for key: String) -> String? {
        if key == "name", !name.isEmpty { return name }
        if (key == "subname" || key == "subnameKey"), !subname.isEmpty { return subname }
        if key == "color", !color.isEmpty { return color }
        if (key == "fontSize" || key == "font-size"), !fontSize.isEmpty { return fontSize }
        if (key == "openType" || key == "open-type"), !openType.isEmpty { return openType }
        let value = values[key]
        return value?.isEmpty == true ? nil : value
    }

    public var resolvedFontSize: CGFloat? {
        guard !fontSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let value = UPActionSheet.parseDimension(fontSize, fallback: -1)
        return value >= 0 && value.isFinite ? value : nil
    }

    private static func mergedValues(_ values: [String: String], name: String, subname: String) -> [String: String] {
        var merged = values
        if !name.isEmpty { merged["name"] = name }
        if !subname.isEmpty {
            merged["subname"] = subname
            merged["subnameKey"] = subname
        }
        return merged
    }

    private static func boolValue(_ raw: String?) -> Bool {
        switch raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes": return true
        default: return false
        }
    }
}
