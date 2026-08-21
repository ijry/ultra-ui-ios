import SwiftUI
import XCTest
@testable import UltraUI

@MainActor
final class UViewPlusCompatibilityTests: XCTestCase {
    func testStyleExposesDeterministicNativeValues() {
        let style = UPStyle([
            "width": "120px",
            "padding": "8px",
            "padding-left": "12px",
            "margin-top": "6px",
            "background-color": "#2979ff",
            "border-radius": "10px",
            "opacity": "0.4",
            "text-align": "right",
            "unsupported-property": "ignored"
        ])

        XCTAssertEqual(style["width"], "120px")
        XCTAssertEqual(style.length(for: "width"), 120)
        XCTAssertEqual(style.padding.top, 8)
        XCTAssertEqual(style.padding.leading, 12)
        XCTAssertEqual(style.padding.bottom, 8)
        XCTAssertEqual(style.margin.top, 6)
        XCTAssertEqual(style.backgroundColor, "#2979ff")
        XCTAssertEqual(style.cornerRadius, 10)
        XCTAssertEqual(style.opacity, 0.4)
        XCTAssertEqual(style.textAlignment, .trailing)
        XCTAssertNil(style.length(for: "unsupported-property"))
    }

    func testExistingPresentationAndPrimitiveInitializersAcceptUpstreamProps() {
        var buttonPlatformEvent = false
        let button = UPButton(
            openType: "share",
            formType: "submit",
            appParameter: "from-ios",
            hoverStopPropagation: false,
            lang: "zh_CN",
            sessionFrom: "support",
            sendMessageTitle: "标题",
            sendMessagePath: "/pages/home",
            sendMessageImg: "https://example.com/card.png",
            showMessageCard: true,
            dataName: "purchase",
            hoverStartTime: 30,
            hoverStayTime: 260,
            stop: false,
            onGetPhoneNumber: { buttonPlatformEvent = true }
        )
        XCTAssertEqual(button.openType, "share")
        XCTAssertEqual(button.formType, "submit")
        XCTAssertEqual(button.hoverStayTime, 260)
        XCTAssertFalse(button.stop)
        button.onGetPhoneNumber?()
        XCTAssertTrue(buttonPlatformEvent)

        let icon = UPIcon(
            index: "featured",
            hoverClass: "u-hover",
            imgMode: "aspectFill",
            width: "24px",
            height: "20px",
            top: "2px",
            stop: true,
            onClick: { _ in }
        )
        XCTAssertEqual(icon.index, "featured")
        XCTAssertEqual(icon.imgMode, "aspectFill")
        XCTAssertEqual(icon.top, "2px")
        XCTAssertTrue(icon.stop)

        let loading = UPLoadingIcon(timingFunction: "linear")
        XCTAssertEqual(loading.timingFunction, "linear")

        var overlayClicked = false
        let overlay = UPOverlay(show: true, onClick: { overlayClicked = true })
        overlay.onClick?()
        XCTAssertTrue(overlayClicked)
    }

    func testExistingContainerInitializersAcceptStylesSlotsAndUpstreamProps() {
        let style = UPStyle(["padding": "8px"])
        let form = UPForm(
            model: .constant([:]),
            borderBottom: false,
            labelPosition: "top",
            labelWidth: "88px",
            labelAlign: "center",
            labelStyle: style
        ) { EmptyView() }
        XCTAssertFalse(form.borderBottom)
        XCTAssertEqual(form.labelPosition, "top")
        XCTAssertEqual(form.labelWidth, "88px")
        XCTAssertEqual(form.labelAlign, "center")
        XCTAssertEqual(form.labelStyle, style)

        let item = UPFormItem(
            label: "验证码",
            prop: "code",
            rules: [UPFormRule(required: true)],
            borderBottom: false,
            labelPosition: "top",
            labelWidth: "100px",
            rightIcon: "arrow-right",
            leftIcon: "email",
            leftIconStyle: style,
            required: true,
            onClick: {}
        ) { EmptyView() } right: {
            Text("发送")
        }
        XCTAssertEqual(item.rightIcon, "arrow-right")
        XCTAssertEqual(item.leftIcon, "email")
        XCTAssertEqual(item.leftIconStyle, style)
        XCTAssertEqual(item.rules.count, 1)

        let popup = UPPopup(
            show: .constant(false),
            overlayStyle: style,
            pageInline: true,
            touchable: true,
            minHeight: "120px",
            maxHeight: "480px",
            onClick: {}
        ) { EmptyView() }
        XCTAssertEqual(popup.overlayStyle, style)
        XCTAssertTrue(popup.pageInline)
        XCTAssertEqual(popup.minHeight, "120px")

        let modal = UPModal(show: .constant(false), contentStyle: style)
        XCTAssertEqual(modal.contentStyle, style)
    }

    func testExistingInputInitializersExposeModelsAndNativeEquivalentProps() {
        let input = UPInput(
            modelValue: .constant("initial"),
            value: "fallback",
            fixed: true,
            disabledColor: "#eeeeee",
            onlyClearableOnFocused: false,
            password: true,
            placeholderClass: "input-placeholder",
            placeholderStyle: UPStyle(["color": "#999999"]),
            showWordLimit: true,
            confirmType: "search",
            confirmHold: true,
            holdKeyboard: true,
            focus: true,
            autoBlur: true,
            disableDefaultPadding: true,
            cursor: 3,
            cursorSpacing: 20,
            selectionStart: 1,
            selectionEnd: 4,
            adjustPosition: false,
            fontSize: "16px",
            color: "#111111",
            prefixIconStyle: UPStyle(["color": "primary"]),
            suffixIconStyle: UPStyle(["color": "success"]),
            shape: "circle",
            formatter: { $0.uppercased() },
            ignoreCompositionEvent: true,
            cursorColor: "#000000",
            passwordVisibilityToggle: false,
            onInput: { _ in },
            onConfirm: { _ in },
            onClear: {}
        )
        XCTAssertEqual(input.modelValue?.wrappedValue, "initial")
        XCTAssertEqual(input.value, "fallback")
        XCTAssertTrue(input.fixed)
        XCTAssertEqual(input.confirmType, "search")
        XCTAssertEqual(input.formatter?("swift"), "SWIFT")
        XCTAssertFalse(input.passwordVisibilityToggle)

        let textarea = UPTextarea(
            modelValue: .constant("initial"),
            value: "fallback",
            placeholderClass: "textarea-placeholder",
            placeholderStyle: UPStyle(["color": "#999999"]),
            confirmType: "send",
            focus: true,
            fixed: true,
            cursorSpacing: 12,
            cursor: 2,
            showConfirmBar: false,
            selectionStart: 1,
            selectionEnd: 3,
            adjustPosition: false,
            disableDefaultPadding: true,
            holdKeyboard: true,
            border: "bottom",
            formatter: { $0.trimmingCharacters(in: .whitespaces) },
            ignoreCompositionEvent: true,
            onLineChange: { _ in },
            onConfirm: { _ in },
            onKeyboardHeightChange: { _ in }
        )
        XCTAssertEqual(textarea.modelValue?.wrappedValue, "initial")
        XCTAssertEqual(textarea.value, "fallback")
        XCTAssertEqual(textarea.confirmType, "send")
        XCTAssertEqual(textarea.formatter?(" swift "), "swift")
        XCTAssertFalse(textarea.showConfirmBar)
    }

    func testToastOptionsRetainTheUpstreamImperativeSurface() {
        var callbackInvoked = false
        let options = UPToastOptions(
            loading: true,
            message: "正在保存",
            icon: "loading",
            type: "loading",
            loadingMode: "spinner",
            show: true,
            overlay: true,
            position: "bottom",
            params: ["source": "editor"],
            duration: 3_000,
            isTab: true,
            url: "/pages/home",
            callback: { callbackInvoked = true },
            back: true,
            zIndex: 10091
        )
        XCTAssertTrue(options.loading)
        XCTAssertEqual(options.params["source"], "editor")
        XCTAssertTrue(options.back)

        let center = UPToastCenter()
        center.show(options)
        XCTAssertEqual(center.message, "正在保存")
        XCTAssertTrue(center.overlay)
        center.hide()
        XCTAssertTrue(callbackInvoked)
    }
}
