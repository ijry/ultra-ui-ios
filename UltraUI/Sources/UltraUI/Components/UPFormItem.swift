import SwiftUI

/// A labeled field container that renders form errors from the surrounding `UPForm`.
@MainActor
public struct UPFormItem<Content: View>: View {
    var label: String
    var prop: String
    var required: Bool
    var labelPosition: String
    var labelWidth: String
    var borderBottom: Bool
    var help: String
    @ViewBuilder var content: () -> Content

    @EnvironmentObject private var form: UPFormContext
    @Environment(\.upTheme) private var theme

    public init(label: String = UPConfig.formItem.label,
                prop: String = UPConfig.formItem.prop,
                required: Bool = UPConfig.formItem.required,
                labelPosition: String = UPConfig.formItem.labelPosition,
                labelWidth: String = UPConfig.formItem.labelWidth,
                borderBottom: Bool = UPConfig.formItem.borderBottom,
                help: String = UPConfig.formItem.help,
                @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.prop = prop
        self.required = required
        self.labelPosition = labelPosition
        self.labelWidth = labelWidth
        self.borderBottom = borderBottom
        self.help = help
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if Self.resolvedLabelPosition(labelPosition) == "top" {
                VStack(alignment: .leading, spacing: 8) {
                    labelView
                    content()
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    labelView
                        .frame(width: UPUnit.parse(labelWidth), alignment: .leading)
                    content()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if !help.isEmpty {
                Text(help)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.tips)
            }

            let error = form.errors[prop] ?? ""
            if Self.shouldShowError(errorType: form.errorType, error: error) {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.error)
            }

            if borderBottom {
                UPLine()
            }
        }
        .padding(.vertical, 10)
    }

    static func resolvedLabelPosition(_ labelPosition: String) -> String {
        labelPosition == "top" ? "top" : "left"
    }

    static func shouldShowError(errorType: String, error: String) -> Bool {
        !error.isEmpty && UPFormContext.resolvedErrorType(errorType) == "message"
    }

    @ViewBuilder
    private var labelView: some View {
        if !label.isEmpty {
            HStack(spacing: 2) {
                if required {
                    Text("*")
                        .foregroundStyle(theme.error)
                }
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(theme.main)
            }
        }
    }
}
