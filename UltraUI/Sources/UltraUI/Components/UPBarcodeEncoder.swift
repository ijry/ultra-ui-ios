import Foundation

/// 上游 `encodeBarcode` 各分支抛出的错误。文案与上游 `new Error(...)` 一致。
public enum UPBarcodeError: Error, Equatable, Sendable {
    case invalidCharacter(format: String, character: String)
    case invalidLength(String)
    case invalidCheckDigit(String)
    case invalidPrefix(String)

    public var message: String {
        switch self {
        case let .invalidCharacter(format, character):
            return "Invalid character in \(format): \(character)"
        case let .invalidLength(text):
            return text
        case let .invalidCheckDigit(text):
            return text
        case let .invalidPrefix(text):
            return text
        }
    }
}

/// 上游 `u-barcode` 里那一整套手写编码器的原生等价实现。
///
/// 上游把每种码制编成一串 `'0'` / `'1'`（1 是黑条），再按模块宽度画矩形。
/// 原生保留同一套「先编码成 0/1 串、再画」的两段式，编码结果逐位与上游一致。
public enum UPBarcodeEncoder {
    /// 上游支持的 `format` 枚举（`validator` 里那一串）。
    public static let supportedFormats = [
        "auto",
        "CODE128", "CODE128A", "CODE128B", "CODE128C",
        "EAN13", "EAN8", "EAN5", "EAN2",
        "UPC", "UPCA", "UPCE",
        "CODE39",
        "ITF", "ITF14",
        "MSI", "MSI10", "MSI11", "MSI1010", "MSI1110",
        "pharmacode",
        "codabar"
    ]

    /// 上游 `encodeBarcode(value, format)`。
    ///
    /// 照抄上游：`switch` 只覆盖 CODE128 / CODE39 / EAN13 / EAN8 / EAN5 / EAN2 /
    /// UPC / UPCA / UPCE 九个分支，`default` 一律退回 CODE128。也就是说 `validator`
    /// 放行的 ITF / MSI / pharmacode / codabar 实际都被当 CODE128 编码。
    public static func encode(_ value: String, format: String) throws -> String {
        switch format {
        case "CODE128", "auto":
            return try encodeCode128(value)
        case "CODE39":
            return try encodeCode39(value)
        case "EAN13":
            return try encodeEAN13(value)
        case "EAN8":
            return try encodeEAN8(value)
        case "EAN5", "EAN2":
            return try encodeEAN52(value, format: format)
        case "UPC", "UPCA":
            return try encodeUPCA(value)
        case "UPCE":
            return try encodeUPCE(value)
        default:
            return try encodeCode128(value)
        }
    }

    // MARK: - CODE128

    /// 上游 `CODE128_CODE_B_CHARS`：Code B 字符集，下标即字符编码。
    static let code128CodeBChars = Array(" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~")

    /// 上游 `encodeCode128(data)`：起始符 104（Code B）、逐字符编码、校验位
    /// `checksum % 103`、结束符 106，末尾再补 5 位安静区 `00000`。
    public static func encodeCode128(_ data: String) throws -> String {
        let startCodeB = 104
        let stop = 106
        var codes = [startCodeB]
        var checksum = startCodeB

        for (index, character) in data.enumerated() {
            guard let code = code128CodeBChars.firstIndex(of: character) else {
                throw UPBarcodeError.invalidCharacter(format: "CODE128", character: String(character))
            }
            codes.append(code)
            checksum += code * (index + 1)
        }

        codes.append(checksum % 103)
        codes.append(stop)

        // 上游 `patterns[code] || ""`：越界时拼空串而不是报错。
        var barcode = codes.map { code128Patterns.indices.contains($0) ? code128Patterns[$0] : "" }.joined()
        barcode += "00000"
        return barcode
    }

    // MARK: - CODE39

    /// 上游 `encodeCode39(data)`：先转大写，首尾加 `*`，字符间插一位 `0` 间隔。
    public static func encodeCode39(_ data: String) throws -> String {
        let upper = data.uppercased()
        guard let delimiter = code39Patterns["*"] else { return "" }
        var barcode = delimiter

        for character in upper {
            guard let pattern = code39Patterns[String(character)] else {
                throw UPBarcodeError.invalidCharacter(format: "CODE39", character: String(character))
            }
            barcode += "0"
            barcode += pattern
        }

        barcode += "0"
        barcode += delimiter
        return barcode
    }

    // MARK: - EAN / UPC

    static let leftOdd = [
        "0001101", "0011001", "0010011", "0111101", "0100011",
        "0110001", "0101111", "0111011", "0110111", "0001011"
    ]

    static let leftEven = [
        "0100111", "0110011", "0011011", "0100001", "0011101",
        "0111001", "0000101", "0010001", "0001001", "0010111"
    ]

    static let rightCodes = [
        "1110010", "1100110", "1101100", "1000010", "1011100",
        "1001110", "1010000", "1000100", "1001000", "1110100"
    ]

    /// 上游 `leftPatterns[0]`：首位数字决定左侧 6 位的奇偶排布。
    static let ean13LeftPatterns = [
        "LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG",
        "LGGLLG", "LGGGLL", "LGLGLG", "LGLGGL", "LGGLGL"
    ]

    /// 上游 `encodeEAN13(data)`：13 位数字 + 校验位校验。
    public static func encodeEAN13(_ data: String) throws -> String {
        let digits = try requireDigits(data, count: 13, message: "EAN13 must be 13 digits")

        var sum = 0
        for index in 0..<12 {
            sum += index % 2 == 0 ? digits[index] : digits[index] * 3
        }
        let checkDigit = (10 - (sum % 10)) % 10
        guard digits[12] == checkDigit else {
            throw UPBarcodeError.invalidCheckDigit("Invalid EAN13 check digit")
        }

        let pattern = Array(ean13LeftPatterns[digits[0]])
        var barcode = "101"
        for index in 1..<7 {
            let digit = digits[index]
            barcode += pattern[index - 1] == "L" ? leftOdd[digit] : leftEven[digit]
        }
        barcode += "01010"
        for index in 7..<13 {
            barcode += rightCodes[digits[index]]
        }
        barcode += "101"
        return barcode
    }

    /// 上游 `encodeEAN8(data)`：注意校验和的权重与 EAN13 相反（`3, 1, 3, 1...`）。
    public static func encodeEAN8(_ data: String) throws -> String {
        let digits = try requireDigits(data, count: 8, message: "EAN8 must be 8 digits")

        var sum = 0
        for index in 0..<7 {
            sum += digits[index] * (index % 2 == 0 ? 3 : 1)
        }
        let checkDigit = (10 - (sum % 10)) % 10
        guard digits[7] == checkDigit else {
            throw UPBarcodeError.invalidCheckDigit("Invalid EAN8 check digit")
        }

        var barcode = "101"
        for index in 0..<4 { barcode += leftOdd[digits[index]] }
        barcode += "01010"
        for index in 4..<8 { barcode += rightCodes[digits[index]] }
        barcode += "101"
        return barcode
    }

    /// 上游 `encodeEAN52(data, format)`。
    ///
    /// 照抄上游两处反直觉：`patterns` 算出来之后压根没用上（每位都用 `leftOdd`），
    /// 且 EAN5 的 `patterns` 只列了 19 项却按 `checksum % 10` 取值。
    public static func encodeEAN52(_ data: String, format: String) throws -> String {
        let length = format == "EAN5" ? 5 : 2
        let digits = try requireDigits(data, count: length, message: "\(format) must be \(length) digits")

        var barcode = "1011"
        for (index, digit) in digits.enumerated() {
            if index > 0 { barcode += "01" }
            barcode += leftOdd[digit]
        }
        return barcode
    }

    /// 上游 `encodeUPCA(data)`：11 位时补校验位，最终按 `'0' + data` 走 EAN13。
    public static func encodeUPCA(_ data: String) throws -> String {
        var value = data
        if isDigits(value, count: 11) {
            let digits = value.compactMap(\.wholeNumberValue)
            var sum = 0
            for index in 0..<11 {
                sum += index % 2 == 0 ? digits[index] * 3 : digits[index]
            }
            value += String((10 - (sum % 10)) % 10)
        }
        guard isDigits(value, count: 12) else {
            throw UPBarcodeError.invalidLength("UPC-A must be 11 or 12 digits")
        }
        return try encodeEAN13("0" + value)
    }

    /// 上游 `encodeUPCE(data)`：7 位时补校验位，首位只允许 0 或 1。
    ///
    /// 照抄上游：`systemDigit` 取出来没用；`checkDigit` 为 0/1/2/3 都落到同一分支。
    public static func encodeUPCE(_ data: String) throws -> String {
        var value = data
        if isDigits(value, count: 7) {
            let digits = value.compactMap(\.wholeNumberValue)
            var sum = 0
            for index in 0..<7 {
                sum += index % 2 == 0 ? digits[index] * 3 : digits[index]
            }
            value += String((10 - (sum % 10)) % 10)
        }
        guard isDigits(value, count: 8) else {
            throw UPBarcodeError.invalidLength("UPC-E must be 7 or 8 digits")
        }
        let characters = Array(value)
        guard characters[0] == "0" || characters[0] == "1" else {
            throw UPBarcodeError.invalidPrefix("UPC-E must start with 0 or 1")
        }

        let pattern: String
        switch characters[7] {
        case "0", "1", "2", "3": pattern = "EEEEOO"
        case "4": pattern = "EEEOOO"
        default: pattern = "EEOOOO"
        }

        var barcode = "101"
        let patternCharacters = Array(pattern)
        for index in 1..<7 {
            guard let digit = characters[index].wholeNumberValue else { continue }
            barcode += patternCharacters[index - 1] == "E" ? leftEven[digit] : leftOdd[digit]
        }
        barcode += "010101"
        barcode += "101"
        return barcode
    }

    // MARK: - 工具

    private static func isDigits(_ value: String, count: Int) -> Bool {
        value.count == count && value.allSatisfy { $0.isASCII && $0.isNumber }
    }

    private static func requireDigits(_ value: String, count: Int, message: String) throws -> [Int] {
        guard isDigits(value, count: count) else { throw UPBarcodeError.invalidLength(message) }
        return value.compactMap(\.wholeNumberValue)
    }

    /// 上游 `getCode128Pattern(code)` 里的 107 项编码表。
    static let code128Patterns = [
        "11011001100", "11001101100", "11001100110", "10010011000",
        "10010001100", "10001001100", "10011001000", "10011000100",
        "10001100100", "11001001000", "11001000100", "11000100100",
        "10110011100", "10011011100", "10011001110", "10111001100",
        "10011101100", "10011100110", "11001110010", "11001011100",
        "11001001110", "11011100100", "11001110100", "11101101110",
        "11101001100", "11100101100", "11100100110", "11101100100",
        "11100110100", "11100110010", "11011011000", "11011000110",
        "11000110110", "10100011000", "10001011000", "10001000110",
        "10110001000", "10001101000", "10001100010", "11010001000",
        "11000101000", "11000100010", "10110111000", "10110001110",
        "10001101110", "10111011000", "10111000110", "10001110110",
        "11101110110", "11010001110", "11000101110", "11011101000",
        "11011100010", "11011101110", "11101011000", "11101000110",
        "11100010110", "11101101000", "11101100010", "11100011010",
        "11101111010", "11001000010", "11110001010", "10100110000",
        "10100001100", "10010110000", "10010000110", "10000101100",
        "10000100110", "10110010000", "10110000100", "10011010000",
        "10011000010", "10000110100", "10000110010", "11000010010",
        "11001010000", "11110111010", "11000010100", "10001111010",
        "10100111100", "10010111100", "10010011110", "10111100100",
        "10011110100", "10011110010", "11110100100", "11110010100",
        "11110010010", "11011011110", "11011110110", "11110110110",
        "10101111000", "10100011110", "10001011110", "10111101000",
        "10111100010", "11110101000", "11110100010", "10111011110",
        "10111101110", "11101011110", "11110101110", "11010000100",
        "11010010000", "11010011100", "11000111010"
    ]

    /// 上游 `encodeCode39(data)` 里的 44 项编码表，`*` 同时充当起止符。
    static let code39Patterns: [String: String] = [
        "0": "101000111011101",
        "1": "111010001010111",
        "2": "101110001010111",
        "3": "111011100010101",
        "4": "101000111010111",
        "5": "111010001110101",
        "6": "101110001110101",
        "7": "101000101110111",
        "8": "111010001011101",
        "9": "101110001011101",
        "A": "111010100010111",
        "B": "101110100010111",
        "C": "111011101000101",
        "D": "101011100010111",
        "E": "111010111000101",
        "F": "101110111000101",
        "G": "101010001110111",
        "H": "111010100011101",
        "I": "101110100011101",
        "J": "101011100011101",
        "K": "111010101000111",
        "L": "101110101000111",
        "M": "111011101010001",
        "N": "101011101000111",
        "O": "111010111010001",
        "P": "101110111010001",
        "Q": "101010111000111",
        "R": "111010101110001",
        "S": "101110101110001",
        "T": "101011101110001",
        "U": "111000101010111",
        "V": "100011101010111",
        "W": "111000111010101",
        "X": "100010111010111",
        "Y": "111000101110101",
        "Z": "100011101110101",
        "-": "100010101110111",
        ".": "111000101011101",
        " ": "100011101011101",
        "*": "100010111011101",
        "$": "100010001000101",
        "/": "100010001010001",
        "+": "100010100010001",
        "%": "101000100010001"
    ]
}
