import XCTest
@testable import UltraUI

final class FormValueTests: XCTestCase {
    func testLiteralValuesProduceExpectedStringValues() {
        let string: UPFormValue = "hello"
        let number: UPFormValue = 42
        let bool: UPFormValue = true
        let empty: UPFormValue = nil

        XCTAssertEqual(string.stringValue, "hello")
        XCTAssertEqual(number.stringValue, "42")
        XCTAssertEqual(bool.stringValue, "true")
        XCTAssertEqual(empty.stringValue, "")
    }

    func testNestedObjectAndArrayPathsReadAndWrite() {
        var model: UPFormModel = [
            "account": .object(["email": .string("old@example.com")]),
            "contacts": .array([.object(["email": .string("first@example.com")])])
        ]

        XCTAssertEqual(UPFormValue.value(at: "account.email", in: model), .string("old@example.com"))
        XCTAssertEqual(UPFormValue.value(at: "contacts.0.email", in: model), .string("first@example.com"))

        UPFormValue.set(.string("new@example.com"), at: "account.email", in: &model)
        UPFormValue.set(.string("second@example.com"), at: "contacts.1.email", in: &model)

        XCTAssertEqual(UPFormValue.value(at: "account.email", in: model), .string("new@example.com"))
        XCTAssertEqual(UPFormValue.value(at: "contacts.1.email", in: model), .string("second@example.com"))
    }

    func testWritingMissingObjectPathCreatesIntermediateObjects() {
        var model: UPFormModel = [:]
        UPFormValue.set(.string("Lin"), at: "profile.name", in: &model)

        XCTAssertEqual(UPFormValue.value(at: "profile.name", in: model), .string("Lin"))
        XCTAssertEqual(UPFormValue.value(at: "missing.path", in: model), .null)
    }
}
