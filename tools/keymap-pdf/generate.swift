import AppKit
import CoreGraphics
import Foundation
import PDFKit

struct Layer {
    let identifier: String
    let name: String
    let bindings: [String]
}

struct LayerActivation {
    var holds = Set<String>()
    var momentarySources = Set<String>()
    var stickySources = Set<String>()
    var toggleSources = Set<String>()
    var switchSources = Set<String>()
    var conditions = Set<String>()
}

struct LayoutFile: Decodable {
    let name: String
    let layouts: [String: Layout]
}

struct Layout: Decodable {
    let layout: [PhysicalKey]
}

struct PhysicalKey: Decodable {
    let x: Double
    let y: Double
    let w: Double?
    let h: Double?
    let r: Double?
    let rx: Double?
    let ry: Double?
}

enum KeyKind {
    case regular
    case navigation
    case number
    case layer
    case modifier
    case system
    case bluetooth
    case rgb
    case transparent
    case disabled
}

struct KeyLegend {
    let main: String
    let detail: String?
    let kind: KeyKind
}

enum GeneratorError: LocalizedError {
    case invalidArguments
    case missingLayout
    case unexpectedLayerCount(Int)
    case unexpectedBindingCount(layer: String, count: Int)
    case unexpectedKeyCount(Int)
    case cannotCreatePDF
    case invalidPDF
    case cannotRenderPreview
    case missingText(String)

    var errorDescription: String? {
        switch self {
        case .invalidArguments:
            return "Usage: generate.swift <keymap> <layout-json> <output-pdf> <preview-directory>"
        case .missingLayout:
            return "The JSON file has no default_layout"
        case .unexpectedLayerCount(let count):
            return "Expected 5 active layers, found \(count)"
        case .unexpectedBindingCount(let layer, let count):
            return "Expected 60 bindings in layer \(layer), found \(count)"
        case .unexpectedKeyCount(let count):
            return "Expected 60 physical keys, found \(count)"
        case .cannotCreatePDF:
            return "Could not create the PDF context"
        case .invalidPDF:
            return "The generated PDF is invalid or does not contain exactly two pages"
        case .cannotRenderPreview:
            return "Could not render a PNG preview"
        case .missingText(let value):
            return "Expected text is missing from the generated PDF: \(value)"
        }
    }
}

let pageWidth: CGFloat = 841.89
let pageHeight: CGFloat = 595.28
let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
let splitGapCompression: CGFloat = 0.85
let keyGapRatio: CGFloat = 0.10

func color(_ red: Int, _ green: Int, _ blue: Int, _ alpha: CGFloat = 1) -> CGColor {
    NSColor(
        calibratedRed: CGFloat(red) / 255,
        green: CGFloat(green) / 255,
        blue: CGFloat(blue) / 255,
        alpha: alpha
    ).cgColor
}

let pageBackground = color(246, 248, 252)
let panelBackground = color(255, 255, 255)
let panelBorder = color(215, 222, 233)
let ink = color(24, 34, 55)
let mutedInk = color(103, 116, 141)

func collapseWhitespace(_ value: String) -> String {
    value.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
}

func parseBindings(_ source: String) -> [String] {
    let matches = source.indices.filter { source[$0] == "&" }
    return matches.enumerated().map { index, start in
        let end = index + 1 < matches.count ? matches[index + 1] : source.endIndex
        return collapseWhitespace(String(source[start..<end]))
    }
}

func parseLayerIdentifiers(_ source: String) throws -> [Int: String] {
    let expression = try NSRegularExpression(
        pattern: #"(?m)^\s*#define\s+([A-Za-z_][A-Za-z0-9_]*)\s+([0-9]+)\s*$"#
    )
    let range = NSRange(source.startIndex..<source.endIndex, in: source)
    var identifiers: [Int: String] = [:]
    for match in expression.matches(in: source, range: range) {
        guard let nameRange = Range(match.range(at: 1), in: source),
              let numberRange = Range(match.range(at: 2), in: source),
              let number = Int(source[numberRange]) else {
            continue
        }
        identifiers[number] = String(source[nameRange])
    }
    return identifiers
}

func parseLayers(_ source: String) throws -> [Layer] {
    guard let keymapStart = source.range(of: "keymap {") else {
        throw GeneratorError.unexpectedLayerCount(0)
    }
    let keymapSource = String(source[keymapStart.lowerBound...])
    let expression = try NSRegularExpression(
        pattern: #"display-name\s*=\s*\"([^\"]+)\"\s*;\s*bindings\s*=\s*<([\s\S]*?)>;"#
    )
    let range = NSRange(keymapSource.startIndex..<keymapSource.endIndex, in: keymapSource)
    let identifiers = try parseLayerIdentifiers(source)
    let layers = expression.matches(in: keymapSource, range: range).enumerated().compactMap { index, match -> Layer? in
        guard let nameRange = Range(match.range(at: 1), in: keymapSource),
              let bindingsRange = Range(match.range(at: 2), in: keymapSource) else {
            return nil
        }
        return Layer(
            identifier: identifiers[index] ?? String(index),
            name: String(keymapSource[nameRange]),
            bindings: parseBindings(String(keymapSource[bindingsRange]))
        )
    }
    guard layers.count == 5 else {
        throw GeneratorError.unexpectedLayerCount(layers.count)
    }
    for layer in layers where layer.bindings.count != 60 {
        throw GeneratorError.unexpectedBindingCount(layer: layer.name, count: layer.bindings.count)
    }
    return layers
}

func splitArguments(_ value: String) -> [String] {
    var arguments: [String] = []
    var current = ""
    var depth = 0
    for character in value {
        if character == "(" { depth += 1 }
        if character == ")" { depth -= 1 }
        if character.isWhitespace && depth == 0 {
            if !current.isEmpty {
                arguments.append(current)
                current = ""
            }
        } else {
            current.append(character)
        }
    }
    if !current.isEmpty { arguments.append(current) }
    return arguments
}

let keyNames: [String: String] = [
    "GRAVE": "`", "N1": "1", "N2": "2", "N3": "3", "N4": "4", "N5": "5",
    "N6": "6", "N7": "7", "N8": "8", "N9": "9", "N0": "0", "MINUS": "-",
    "EQUAL": "=", "PLUS": "+", "ASTRK": "*", "FSLH": "/", "BSLH": "\\",
    "SEMI": ";", "SQT": "'", "COMMA": ",", "DOT": ".", "LBKT": "[", "RBKT": "]",
    "TAB": "Tab", "ESC": "Esc", "BSPC": "Backspace", "DEL": "Delete", "RET": "Enter",
    "SPACE": "Space", "HOME": "Home", "END": "End", "UP": "Up", "DOWN": "Down",
    "LEFT": "Left", "RIGHT": "Right", "PG_UP": "Page Up", "PG_DN": "Page Down",
    "PSCRN": "Screen shot", "GLOBE": "Globe", "C_PWR": "Power", "C_MUTE": "Mute",
    "C_VOL_UP": "Vol\n+", "C_VOL_DN": "Vol\n-", "LGUI": "Cmd", "RGUI": "Cmd",
    "LALT": "Opt", "RALT": "Opt", "LCTRL": "Ctrl", "RCTRL": "Ctrl",
    "LSHFT": "Shift", "RSHFT": "Shift",
]

let modifierNames: [String: String] = [
    "LG": "Cmd", "LA": "Opt", "LC": "Ctrl", "LS": "Shift",
    "LGUI": "Cmd", "RGUI": "Cmd", "LALT": "Opt", "RALT": "Opt",
    "LCTRL": "Ctrl", "RCTRL": "Ctrl", "LSHFT": "Shift", "RSHFT": "Shift",
]

var unknownKeyExpressions = Set<String>()
var fallbackBindings = Set<String>()
var activationWarnings = Set<String>()

func isFunctionKey(_ expression: String) -> Bool {
    guard expression.first == "F",
          let number = Int(expression.dropFirst()) else {
        return false
    }
    return (1...24).contains(number)
}

func fallbackKeyName(_ expression: String) -> String {
    expression.replacingOccurrences(of: "_", with: " ").capitalized
}

func formatKey(_ expression: String) -> String {
    if let opening = expression.firstIndex(of: "("), expression.last == ")" {
        let modifier = String(expression[..<opening])
        let innerStart = expression.index(after: opening)
        let innerEnd = expression.index(before: expression.endIndex)
        if let name = modifierNames[modifier] {
            return "\(name)+\(formatKey(String(expression[innerStart..<innerEnd])))"
        }
    }
    if let name = keyNames[expression] { return name }
    if isFunctionKey(expression) { return expression }
    if expression.count == 1 { return expression }
    unknownKeyExpressions.insert(expression)
    return fallbackKeyName(expression)
}

func resolvedLayerIdentifier(_ value: String, layers: [Layer]) -> String {
    if let index = Int(value), layers.indices.contains(index) {
        return layers[index].identifier
    }
    return value
}

func activationTexts(for layers: [Layer], source: String) throws -> [String: String] {
    var activations = Dictionary(
        uniqueKeysWithValues: layers.map { ($0.identifier, LayerActivation()) }
    )
    let identifiers = Set(layers.map(\.identifier))

    func update(
        target value: String,
        referencedBy binding: String,
        _ change: (inout LayerActivation, String) -> Void
    ) {
        let target = resolvedLayerIdentifier(value, layers: layers)
        guard identifiers.contains(target), var activation = activations[target] else {
            activationWarnings.insert("layer reference '\(value)' in binding '\(binding)' does not match a parsed layer")
            return
        }
        change(&activation, target)
        activations[target] = activation
    }

    for sourceLayer in layers {
        for binding in sourceLayer.bindings {
            let arguments = splitArguments(binding)
            guard let behavior = arguments.first else { continue }
            switch behavior {
            case "&lt":
                guard arguments.count == 3 else { continue }
                update(target: arguments[1], referencedBy: binding) { activation, target in
                    let tap = formatKey(arguments[2]).replacingOccurrences(of: "\n", with: " ")
                    activation.holds.insert("Hold \(target) (tap \(tap))")
                }
            case "&tlh":
                guard arguments.count == 3 else { continue }
                update(target: arguments[1], referencedBy: binding) { activation, target in
                    let tap = formatKey(arguments[2]).replacingOccurrences(of: "\n", with: " ")
                    activation.holds.insert("Hold to switch to \(target) (tap \(tap))")
                }
            case "&mo":
                guard arguments.count == 2 else { continue }
                update(target: arguments[1], referencedBy: binding) { activation, _ in
                    activation.momentarySources.insert(sourceLayer.name)
                }
            case "&tog":
                guard arguments.count == 2 else { continue }
                update(target: arguments[1], referencedBy: binding) { activation, _ in
                    activation.toggleSources.insert(sourceLayer.name)
                }
            case "&sl":
                guard arguments.count == 2 else { continue }
                update(target: arguments[1], referencedBy: binding) { activation, _ in
                    activation.stickySources.insert(sourceLayer.name)
                }
            case "&to":
                guard arguments.count == 2 else { continue }
                update(target: arguments[1], referencedBy: binding) { activation, _ in
                    activation.switchSources.insert(sourceLayer.name)
                }
            default:
                continue
            }
        }
    }

    let conditionalExpression = try NSRegularExpression(
        pattern: #"if-layers\s*=\s*<([^>]*)>\s*;\s*then-layers?\s*=\s*<([^>]*)>\s*;"#
    )
    let conditionalRange = NSRange(source.startIndex..<source.endIndex, in: source)
    for match in conditionalExpression.matches(in: source, range: conditionalRange) {
        guard let requiredRange = Range(match.range(at: 1), in: source),
              let targetsRange = Range(match.range(at: 2), in: source) else {
            continue
        }
        let required = collapseWhitespace(String(source[requiredRange]))
            .split(separator: " ")
            .map { resolvedLayerIdentifier(String($0), layers: layers) }
        let condition = required.joined(separator: " + ")
        let targets = collapseWhitespace(String(source[targetsRange])).split(separator: " ")
        for target in targets {
            let description = "conditional layer \(condition) -> \(target)"
            update(target: String(target), referencedBy: description) { activation, _ in
                activation.conditions.insert(condition)
            }
        }
    }

    var texts: [String: String] = [:]
    for (index, layer) in layers.enumerated() {
        guard let activation = activations[layer.identifier] else { continue }
        var parts: [String] = index == 0 ? ["Default layer"] : []
        parts.append(contentsOf: activation.holds.sorted())
        parts.append(contentsOf: activation.conditions.sorted().map { "Active with \($0)" })
        if !activation.momentarySources.isEmpty {
            parts.append("Hold from \(activation.momentarySources.sorted().joined(separator: ", "))")
        }
        if !activation.stickySources.isEmpty {
            parts.append("Sticky from \(activation.stickySources.sorted().joined(separator: ", "))")
        }
        if !activation.toggleSources.isEmpty {
            parts.append("Toggle lock in \(activation.toggleSources.sorted().joined(separator: ", "))")
        }
        if !activation.switchSources.isEmpty {
            parts.append("Switch from \(activation.switchSources.sorted().joined(separator: ", "))")
        }
        if parts.isEmpty {
            activationWarnings.insert("no activation binding found for layer '\(layer.identifier)' (\(layer.name))")
            parts.append("No activation binding found")
        }
        texts[layer.identifier] = parts.joined(separator: "; ")
    }
    return texts
}

func wrapped(_ text: String, limit: Int = 8) -> String {
    guard text.count > limit else { return text }
    if text.contains("+") {
        let components = text.split(separator: "+").map(String.init)
        if components.count > 1 {
            let split = max(1, (components.count + 1) / 2)
            return components[..<split].joined(separator: "+") + "+\n" + components[split...].joined(separator: "+")
        }
    }
    let words = text.split(separator: " ").map(String.init)
    if words.count > 1 {
        let split = max(1, words.count / 2)
        return words[..<split].joined(separator: " ") + "\n" + words[split...].joined(separator: " ")
    }
    if text.count > limit {
        let midpoint = text.index(text.startIndex, offsetBy: text.count / 2)
        return String(text[..<midpoint]) + "\n" + String(text[midpoint...])
    }
    return text
}

func keyKind(for key: String) -> KeyKind {
    let navigation = ["HOME", "END", "UP", "DOWN", "LEFT", "RIGHT", "PG_UP", "PG_DN", "DEL", "PSCRN"]
    let numbers = ["N0", "N1", "N2", "N3", "N4", "N5", "N6", "N7", "N8", "N9", "MINUS", "EQUAL", "PLUS", "ASTRK", "FSLH", "DOT"]
    if navigation.contains(key) { return .navigation }
    if numbers.contains(key) { return .number }
    if key.hasPrefix("C_") { return .system }
    if modifierNames[key] != nil || key.contains("LG(") || key.contains("LA(") || key.contains("LC(") || key.contains("LS(") {
        return .modifier
    }
    return .regular
}

func legend(for binding: String) -> KeyLegend {
    let arguments = splitArguments(binding)
    guard let behavior = arguments.first else {
        return KeyLegend(main: "", detail: nil, kind: .disabled)
    }
    switch behavior {
    case "&none":
        guard arguments.count == 1 else { break }
        return KeyLegend(main: "", detail: nil, kind: .disabled)
    case "&trans":
        guard arguments.count == 1 else { break }
        return KeyLegend(main: "TRANS", detail: nil, kind: .transparent)
    case "&kp":
        guard arguments.count >= 2 else { break }
        let key = arguments.dropFirst().joined()
        if key == "LC(LS(LG(N4)))" {
            return KeyLegend(main: "Shot\nClip", detail: nil, kind: .system)
        }
        if key == "LS(LG(N4))" {
            return KeyLegend(main: "Shot\nFile", detail: nil, kind: .system)
        }
        return KeyLegend(main: wrapped(formatKey(key)), detail: nil, kind: keyKind(for: key))
    case "&mt":
        guard arguments.count == 3 else { break }
        return KeyLegend(
            main: wrapped(formatKey(arguments[2])),
            detail: "hold \(wrapped(formatKey(arguments[1]), limit: 12))",
            kind: .modifier
        )
    case "&mcw":
        guard arguments.count == 3 else { break }
        return KeyLegend(
            main: "Caps\nWord",
            detail: "hold \(wrapped(formatKey(arguments[1]), limit: 12))",
            kind: .modifier
        )
    case "&lt", "&tlh":
        guard arguments.count == 3 else { break }
        return KeyLegend(
            main: wrapped(formatKey(arguments[2])),
            detail: "hold \(arguments[1])",
            kind: .layer
        )
    case "&sk":
        guard arguments.count == 2 else { break }
        return KeyLegend(main: "Sticky\n\(formatKey(arguments[1]))", detail: nil, kind: .modifier)
    case "&tog":
        guard arguments.count == 2 else { break }
        return KeyLegend(main: "\(arguments[1])\nlock", detail: nil, kind: .layer)
    case "&mo":
        guard arguments.count == 2 else { break }
        return KeyLegend(main: arguments[1], detail: "hold layer", kind: .layer)
    case "&sl":
        guard arguments.count == 2 else { break }
        return KeyLegend(main: arguments[1], detail: "sticky layer", kind: .layer)
    case "&to":
        guard arguments.count == 2 else { break }
        return KeyLegend(main: arguments[1], detail: "switch layer", kind: .layer)
    case "&caps_word":
        guard arguments.count == 1 else { break }
        return KeyLegend(main: "Caps\nWord", detail: nil, kind: .modifier)
    case "&bt":
        if arguments.count == 2, arguments[1] == "BT_CLR" {
            return KeyLegend(main: "BT\nclear", detail: nil, kind: .bluetooth)
        }
        if arguments.count == 3, arguments[1] == "BT_SEL", let index = Int(arguments[2]) {
            return KeyLegend(main: "BT \(index + 1)", detail: nil, kind: .bluetooth)
        }
        break
    case "&rgb_ug":
        if arguments.count == 2, arguments[1] == "RGB_TOG" {
            return KeyLegend(main: "RGB", detail: "toggle", kind: .rgb)
        }
        let labels: [String: String] = [
            "RGB_HUD": "Hue -", "RGB_HUI": "Hue +", "RGB_SAD": "Sat -", "RGB_SAI": "Sat +",
            "RGB_BRD": "Bright -", "RGB_BRI": "Bright +", "RGB_EFF": "Effect",
        ]
        guard arguments.count == 2, let label = labels[arguments[1]] else { break }
        return KeyLegend(main: wrapped(label), detail: nil, kind: .rgb)
    case "&ext_power":
        guard arguments.count == 2,
              ["EP_OFF", "EP_ON", "EP_TOG"].contains(arguments[1]) else { break }
        return KeyLegend(main: "Ext\npower", detail: nil, kind: .system)
    case "&sys_reset":
        guard arguments.count == 1 else { break }
        return KeyLegend(main: "Reset", detail: nil, kind: .system)
    case "&bootloader":
        guard arguments.count == 1 else { break }
        return KeyLegend(main: "Boot\nloader", detail: nil, kind: .system)
    case "&studio_unlock":
        guard arguments.count == 1 else { break }
        return KeyLegend(main: "Studio\nunlock", detail: nil, kind: .system)
    default:
        break
    }
    fallbackBindings.insert(binding)
    return KeyLegend(main: wrapped(behavior.dropFirst().replacingOccurrences(of: "_", with: " ").capitalized), detail: nil, kind: .regular)
}

func printWarnings() {
    for expression in unknownKeyExpressions.sorted() {
        let fallback = fallbackKeyName(expression).replacingOccurrences(of: "\n", with: " ")
        let message = "warning: no explicit PDF label for key expression '\(expression)'; using '\(fallback)'\n"
        FileHandle.standardError.write(Data(message.utf8))
    }
    for binding in fallbackBindings.sorted() {
        let message = "warning: no complete PDF handler for binding '\(binding)'; using a fallback label\n"
        FileHandle.standardError.write(Data(message.utf8))
    }
    for warning in activationWarnings.sorted() {
        let message = "warning: \(warning)\n"
        FileHandle.standardError.write(Data(message.utf8))
    }
}

func fillColor(for kind: KeyKind) -> CGColor {
    switch kind {
    case .regular: return color(252, 253, 255)
    case .navigation: return color(222, 238, 255)
    case .number: return color(255, 237, 207)
    case .layer: return color(225, 230, 255)
    case .modifier: return color(239, 229, 255)
    case .system: return color(255, 222, 226)
    case .bluetooth: return color(218, 245, 239)
    case .rgb: return color(245, 221, 247)
    case .transparent: return color(234, 239, 246)
    case .disabled: return color(222, 227, 235)
    }
}

func strokeColor(for kind: KeyKind) -> CGColor {
    switch kind {
    case .regular: return color(180, 192, 210)
    case .navigation: return color(82, 148, 222)
    case .number: return color(229, 144, 38)
    case .layer: return color(83, 101, 211)
    case .modifier: return color(146, 99, 212)
    case .system: return color(226, 91, 104)
    case .bluetooth: return color(48, 167, 148)
    case .rgb: return color(182, 90, 186)
    case .transparent: return color(167, 181, 201)
    case .disabled: return color(180, 190, 205)
    }
}

func drawText(
    _ text: String,
    in rect: CGRect,
    size: CGFloat,
    weight: NSFont.Weight = .regular,
    color: CGColor = ink,
    alignment: NSTextAlignment = .left
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byWordWrapping
    paragraph.lineSpacing = 0
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: NSColor(cgColor: color) ?? NSColor.black,
        .paragraphStyle: paragraph,
    ]
    let value = NSAttributedString(string: text, attributes: attributes)
    let measured = value.boundingRect(
        with: CGSize(width: rect.width, height: 1_000),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    )
    let drawRect = CGRect(x: rect.minX, y: rect.midY - measured.height / 2, width: rect.width, height: measured.height + 2)
    value.draw(with: drawRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
}

func rotatePoint(_ point: CGPoint, around pivot: CGPoint, degrees: Double) -> CGPoint {
    let radians = CGFloat(degrees * .pi / 180)
    let deltaX = point.x - pivot.x
    let deltaY = point.y - pivot.y
    return CGPoint(
        x: pivot.x + deltaX * cos(radians) - deltaY * sin(radians),
        y: pivot.y + deltaX * sin(radians) + deltaY * cos(radians)
    )
}

func transformedPoint(_ point: CGPoint, for key: PhysicalKey) -> CGPoint {
    let rotation = key.r ?? 0
    let pivot = CGPoint(x: key.rx ?? key.x, y: key.ry ?? key.y)
    var transformed = rotation == 0 ? point : rotatePoint(point, around: pivot, degrees: rotation)
    if key.x > 7.5 {
        transformed.x -= splitGapCompression
    }
    return transformed
}

func keyCenter(_ key: PhysicalKey) -> CGPoint {
    transformedPoint(
        CGPoint(x: key.x + (key.w ?? 1) / 2, y: key.y + (key.h ?? 1) / 2),
        for: key
    )
}

func keyCorners(_ key: PhysicalKey) -> [CGPoint] {
    let width = key.w ?? 1
    let height = key.h ?? 1
    return [
        CGPoint(x: key.x, y: key.y),
        CGPoint(x: key.x + width, y: key.y),
        CGPoint(x: key.x + width, y: key.y + height),
        CGPoint(x: key.x, y: key.y + height),
    ].map { transformedPoint($0, for: key) }
}

func drawKeyboard(context: CGContext, keys: [PhysicalKey], bindings: [String], in rect: CGRect) {
    let corners = keys.flatMap(keyCorners)
    let minX = corners.map(\.x).min() ?? 0
    let maxX = corners.map(\.x).max() ?? 14
    let minY = corners.map(\.y).min() ?? 0
    let maxY = corners.map(\.y).max() ?? 5.4
    let rawWidth = maxX - minX
    let rawHeight = maxY - minY
    let scale = min(rect.width / rawWidth, rect.height / rawHeight)
    let drawingWidth = rawWidth * scale
    let drawingHeight = rawHeight * scale
    let originX = rect.midX - drawingWidth / 2
    let originY = rect.midY - drawingHeight / 2
    let gap = max(1.2, scale * keyGapRatio)

    for (index, key) in keys.enumerated() {
        let width = CGFloat(key.w ?? 1) * scale - gap
        let height = CGFloat(key.h ?? 1) * scale - gap
        let transformedCenter = keyCenter(key)
        let centerX = originX + (transformedCenter.x - minX) * scale
        let centerY = originY + drawingHeight - (transformedCenter.y - minY) * scale
        let rotation = CGFloat(-(key.r ?? 0) * .pi / 180)
        let keyRect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
        let keyLegend = legend(for: bindings[index])

        context.saveGState()
        context.translateBy(x: centerX, y: centerY)
        context.rotate(by: rotation)
        let path = CGPath(
            roundedRect: keyRect,
            cornerWidth: min(4.5, width * 0.11),
            cornerHeight: min(4.5, width * 0.11),
            transform: nil
        )
        context.setShadow(offset: CGSize(width: 0, height: -0.6), blur: 1.2, color: color(18, 35, 62, 0.13))
        context.setFillColor(fillColor(for: keyLegend.kind))
        context.addPath(path)
        context.fillPath()
        context.setShadow(offset: .zero, blur: 0, color: nil)
        context.setStrokeColor(strokeColor(for: keyLegend.kind))
        context.setLineWidth(max(0.65, scale * 0.025))
        context.addPath(path)
        context.strokePath()

        if !keyLegend.main.isEmpty {
            let hasDetail = keyLegend.detail != nil
            let mainRect = CGRect(
                x: keyRect.minX + 2,
                y: keyRect.minY + (hasDetail ? height * 0.32 : 2),
                width: width - 4,
                height: hasDetail ? height * 0.64 : height - 4
            )
            let compactLength = keyLegend.main.replacingOccurrences(of: "\n", with: "").count
            let mainSize = max(5.0, min(7.5, scale * (compactLength > 12 ? 0.15 : compactLength > 8 ? 0.17 : 0.20)))
            drawText(keyLegend.main, in: mainRect, size: mainSize, weight: .semibold, color: ink, alignment: .center)
        }
        if let detail = keyLegend.detail {
            drawText(
                detail,
                in: CGRect(x: keyRect.minX + 2, y: keyRect.minY + 2, width: width - 4, height: height * 0.34),
                size: max(4.1, min(5.4, scale * 0.13)),
                weight: .medium,
                color: mutedInk,
                alignment: .center
            )
        }
        context.restoreGState()
    }
}

func accentColor(for layer: String) -> CGColor {
    switch layer {
    case "nav/num": return color(219, 129, 34)
    case "tab/nav": return color(49, 112, 189)
    case "adjust": return color(155, 74, 169)
    case "window": return color(39, 143, 126)
    default: return color(54, 75, 99)
    }
}

func drawLayerPanel(
    context: CGContext,
    layer: Layer,
    activationText: String,
    keys: [PhysicalKey],
    rect: CGRect
) {
    let path = CGPath(roundedRect: rect, cornerWidth: 10, cornerHeight: 10, transform: nil)
    context.setFillColor(panelBackground)
    context.addPath(path)
    context.fillPath()
    context.setStrokeColor(panelBorder)
    context.setLineWidth(0.8)
    context.addPath(path)
    context.strokePath()

    let accent = accentColor(for: layer.name)
    context.setFillColor(accent)
    context.fillEllipse(in: CGRect(x: rect.minX + 14, y: rect.maxY - 28, width: 9, height: 9))
    drawText(layer.name, in: CGRect(x: rect.minX + 30, y: rect.maxY - 32, width: 145, height: 21), size: 13, weight: .bold)
    drawText(
        activationText,
        in: CGRect(x: rect.minX + 178, y: rect.maxY - 31, width: rect.width - 192, height: 19),
        size: 7.4,
        weight: .medium,
        color: mutedInk,
        alignment: .right
    )
    drawKeyboard(
        context: context,
        keys: keys,
        bindings: layer.bindings,
        in: CGRect(x: rect.minX + 12, y: rect.minY + 10, width: rect.width - 24, height: rect.height - 50)
    )
}

func drawHeader(pageNumber: Int) {
    drawText("Sofle Choc Pro BT", in: CGRect(x: 24, y: pageHeight - 39, width: 360, height: 26), size: 20, weight: .bold)
    drawText(
        "ZMK keymap - physical layout",
        in: CGRect(x: 390, y: pageHeight - 36, width: pageWidth - 414, height: 20),
        size: 9,
        weight: .medium,
        color: mutedInk,
        alignment: .right
    )
    drawText(
        "Page \(pageNumber) of 2  |  Generated from config/sofle_choc_pro.keymap",
        in: CGRect(x: 24, y: 12, width: pageWidth - 48, height: 15),
        size: 6.8,
        color: mutedInk,
        alignment: .center
    )
}

func drawLegend(rect: CGRect) {
    let entries: [(String, KeyKind)] = [
        ("Standard", .regular), ("Navigation", .navigation), ("Numbers", .number),
        ("Layer", .layer), ("Modifier", .modifier), ("System", .system),
        ("Bluetooth", .bluetooth), ("RGB", .rgb), ("Transparent", .transparent),
        ("Disabled", .disabled),
    ]
    let itemWidth = rect.width / CGFloat(entries.count)
    for (index, entry) in entries.enumerated() {
        let x = rect.minX + CGFloat(index) * itemWidth
        let swatch = CGRect(x: x + 2, y: rect.minY + 15, width: 13, height: 13)
        let path = CGPath(roundedRect: swatch, cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)
        NSGraphicsContext.current?.cgContext.setFillColor(fillColor(for: entry.1))
        NSGraphicsContext.current?.cgContext.addPath(path)
        NSGraphicsContext.current?.cgContext.fillPath()
        NSGraphicsContext.current?.cgContext.setStrokeColor(strokeColor(for: entry.1))
        NSGraphicsContext.current?.cgContext.addPath(path)
        NSGraphicsContext.current?.cgContext.strokePath()
        drawText(entry.0, in: CGRect(x: x + 19, y: rect.minY + 14, width: itemWidth - 20, height: 15), size: 5.8, weight: .medium)
    }
    drawText(
        "TRANS passes through to the next lower active layer. Empty grey keys are disabled.",
        in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 11),
        size: 6.3,
        color: mutedInk,
        alignment: .center
    )
}

func beginPage(_ context: CGContext) {
    context.beginPDFPage(nil)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    context.setFillColor(pageBackground)
    context.fill(pageRect)
}

func endPage(_ context: CGContext) {
    NSGraphicsContext.restoreGraphicsState()
    context.endPDFPage()
}

func renderPDF(_ pdfURL: URL, to directory: URL, expectedLayerNames: [String]) throws {
    guard let document = PDFDocument(url: pdfURL), document.pageCount == 2 else {
        throw GeneratorError.invalidPDF
    }
    if FileManager.default.fileExists(atPath: directory.path) {
        try FileManager.default.removeItem(at: directory)
    }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    for pageIndex in 0..<document.pageCount {
        guard let page = document.page(at: pageIndex) else { throw GeneratorError.invalidPDF }
        let bounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2
        let pixelWidth = Int(bounds.width * scale)
        let pixelHeight = Int(bounds.height * scale)
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
            throw GeneratorError.cannotRenderPreview
        }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        let context = graphics.cgContext
        context.setFillColor(color(255, 255, 255))
        context.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        context.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context)
        NSGraphicsContext.restoreGraphicsState()
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            throw GeneratorError.cannotRenderPreview
        }
        try png.write(to: directory.appendingPathComponent("page-\(pageIndex + 1).png"))
    }

    let extractedText = (0..<document.pageCount)
        .compactMap { document.page(at: $0)?.string }
        .joined(separator: "\n")
    for name in expectedLayerNames where !extractedText.contains(name) {
        throw GeneratorError.missingText(name)
    }
    print("PDF pages: \(document.pageCount)")
    print("Extracted text characters: \(extractedText.count)")
}

guard CommandLine.arguments.count == 5 else {
    throw GeneratorError.invalidArguments
}

let keymapURL = URL(fileURLWithPath: CommandLine.arguments[1])
let layoutURL = URL(fileURLWithPath: CommandLine.arguments[2])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[3])
let previewURL = URL(fileURLWithPath: CommandLine.arguments[4])
let source = try String(contentsOf: keymapURL, encoding: .utf8)
let layers = try parseLayers(source)
let activationLabels = try activationTexts(for: layers, source: source)
let layoutFile = try JSONDecoder().decode(LayoutFile.self, from: Data(contentsOf: layoutURL))
guard let layout = layoutFile.layouts["default_layout"] else { throw GeneratorError.missingLayout }
let keys = layout.layout
guard keys.count == 60 else { throw GeneratorError.unexpectedKeyCount(keys.count) }

try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
var mediaBox = pageRect
guard let consumer = CGDataConsumer(url: outputURL as CFURL),
      let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
    throw GeneratorError.cannotCreatePDF
}

beginPage(context)
drawLayerPanel(context: context, layer: layers[0], activationText: activationLabels[layers[0].identifier] ?? "", keys: keys, rect: CGRect(x: 24, y: 305, width: pageWidth - 48, height: 232))
drawLayerPanel(context: context, layer: layers[1], activationText: activationLabels[layers[1].identifier] ?? "", keys: keys, rect: CGRect(x: 24, y: 42, width: 386, height: 247))
drawLayerPanel(context: context, layer: layers[2], activationText: activationLabels[layers[2].identifier] ?? "", keys: keys, rect: CGRect(x: 432, y: 42, width: 386, height: 247))
drawHeader(pageNumber: 1)
endPage(context)

beginPage(context)
drawLayerPanel(context: context, layer: layers[3], activationText: activationLabels[layers[3].identifier] ?? "", keys: keys, rect: CGRect(x: 24, y: 310, width: pageWidth - 48, height: 227))
drawLayerPanel(context: context, layer: layers[4], activationText: activationLabels[layers[4].identifier] ?? "", keys: keys, rect: CGRect(x: 24, y: 82, width: pageWidth - 48, height: 212))
drawLegend(rect: CGRect(x: 24, y: 31, width: pageWidth - 48, height: 42))
drawHeader(pageNumber: 2)
endPage(context)

printWarnings()
context.closePDF()
try renderPDF(outputURL, to: previewURL, expectedLayerNames: layers.map(\.name))
print("Created: \(outputURL.path)")
