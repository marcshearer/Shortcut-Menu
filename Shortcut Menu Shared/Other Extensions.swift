//
//  Other Extensions.swift
// Bridge Score
//
//  Created by Marc Shearer on 01/02/2021.
//

import SwiftUI

#if canImport(UIKit)
class SearchBar : UISearchBar {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.layer.borderWidth = 1
        self.layer.borderColor = self.barTintColor?.cgColor
    }
}

extension UIView {
    
    func absoluteFrame() -> CGRect {
        if let superview = self.superview {
            return superview.convert(self.frame, to: nil)
        } else {
            return CGRect()
        }
    }
    
    
    public func addShadow(shadowSize: CGSize = CGSize(width: 4.0, height: 4.0), shadowColor: UIColor? = nil, shadowOpacity: CGFloat = 0.2, shadowRadius: CGFloat? = nil) {
        
        let shadowColor = shadowColor ?? UIColor.black
        let shadowRadius = shadowRadius ?? min(shadowSize.width, shadowSize.height) / 2.0
        self.layer.shadowOpacity = Float(shadowOpacity)
        self.layer.shadowOffset = shadowSize
        self.layer.shadowColor = shadowColor.cgColor
        self.layer.shadowRadius = shadowRadius
    }
    
    public func removeShadow() {
        self.layer.shadowOffset = CGSize()
        self.clipsToBounds = false
    }
    
    public func roundCorners(cornerRadius: CGFloat) {
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true
    }
    
    public func roundCorners(cornerRadius: CGFloat, topRounded:Bool = true, bottomRounded: Bool = true) {
        if topRounded || bottomRounded {
            var corners: UIRectCorner = []
            if topRounded && bottomRounded {
                corners = .allCorners
            } else if topRounded {
                corners = [.topLeft, .topRight]
            } else {
                corners = [.bottomLeft, .bottomRight]
            }
            self.roundCorners(cornerRadius: cornerRadius, corners: corners)
        } else {
            self.layer.mask = nil
        }
    }
    
    public func roundCorners(cornerRadius: CGFloat, corners: UIRectCorner) {
        self.layer.mask = nil
        if !corners.isEmpty {
            let layerMask = UIBezierPath(roundedRect: self.frame, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            let layer = CAShapeLayer()
            layer.frame = self.bounds
            layer.path = layerMask.cgPath
            self.layer.mask = layer
        }
    }
    
    public func removeRoundCorners() {
        self.layer.mask = nil
    }
    
    func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, identifier: String) {
        self.addGestureRecognizer(gestureRecognizer)
        gestureRecognizer.name = identifier
    }
    
    func identifyGestureRecognizers(isEnabled: Bool?) -> [String] {
        return identifyViewGestureRecognizers(view: self, isEnabled: isEnabled)
    }
    
    func identifyViewGestureRecognizers(view: UIView, isEnabled: Bool?) -> [String] {
        var results: [String] = []
        if let gestureRecognizers = gestureRecognizers {
            for recognizer in gestureRecognizers {
                if isEnabled == nil || isEnabled == recognizer.isEnabled {
                    results.append(recognizer.name ?? "Unknown")
                }
            }
        }
        for view in subviews {
            results.append(contentsOf: view.identifyViewGestureRecognizers(view: view, isEnabled: isEnabled))
        }
        return results
    }
}

extension CGPoint {
    
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow((self.x - point.x), 2) + pow((self.y - point.y), 2))
    }
    
    func offsetBy(dx: CGFloat = 0.0, dy: CGFloat = 0.0) -> CGPoint {
        return CGPoint(x: self.x + dx, y: self.y + dy)
    }
}

extension CGRect {
    
    var center: CGPoint {
        get {
            return CGPoint(x: self.midX, y: self.midY)
        }
    }

    func offsetBy(dx: CGFloat = 0.0, dy: CGFloat = 0.0) -> CGRect {
        return CGRect(x: self.minX + dx, y: self.minY + dy, width: self.width, height: self.height)
    }
    
    func offsetBy(offset: CGPoint) -> CGRect {
        return CGRect(x: self.minX + offset.x, y: self.minY + offset.y, width: self.width, height: self.height)
    }
    
    func grownBy(dx: CGFloat = 0.0, dy: CGFloat = 0.0) -> CGRect {
        return CGRect(x: self.minX - dx, y: self.minY - dy, width: self.width + (2 * dx), height: self.height + (2 * dy))
    }
}

extension CGPoint {
    
    static prefix func - (point: CGPoint) -> CGPoint {
        return CGPoint(x: -point.x, y: -point.y)
    }
}

extension UIImage {
    convenience init(color: UIColor, size: CGSize) {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        color.set()
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        self.init(data: image.pngData()!)!
    }
    
    convenience init?(prefixed name: String) {
        if name.left(7) == "system." {
            self.init(systemName: name.right(name.length-7))
        } else {
            self.init(named: name)
        }
    }
    
    public var asTemplate: UIImage {
        return self.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
    }
    
    public func crop(to frame: CGRect) -> UIImage? {
        let scaledFrame = CGRect(x: frame.origin.x * self.scale, y: frame.origin.y * self.scale, width: frame.size.width * self.scale, height: frame.size.height * self.scale)
        
        if let coreImage = self.cgImage?.cropping(to: scaledFrame) {
            let croppedImage = UIImage(cgImage: coreImage, scale: self.scale, orientation: self.imageOrientation)
            return croppedImage
        } else {
            return nil
        }
    }
}
#endif

extension Array {
    
    mutating func rotate(by rotations: Int) {
        if rotations == 0 || self.count <= 1 {
            return
        }

       let length = self.count
       let rotations = (length + rotations % length) % length

       let reversed: Array = self.reversed()
       let leftPart: Array = reversed[0..<rotations].reversed()
       let rightPart: Array = reversed[rotations..<length].reversed()
       self = leftPart + rightPart
    }
 
    func element(_ index: Int) -> Element? {
        var result: Element?
        if index >= 0 && index < self.count {
            result = self[index]
        }
        return result
    }
}

extension Dictionary {
    public static func +=(lhs: inout [Key: Value], rhs: [Key: Value]) {
        rhs.forEach({ lhs[$0] = $1})
    }
}

extension AttributedString {
    
    init(_ string: String, color: Color) {
        self.init(string)
        self.foregroundColor = color
    }
    
    public static func + (string: String, attributed: AttributedString) -> AttributedString {
        AttributedString(string) + attributed
    }

    public static func + (attributed: AttributedString, string: String) -> AttributedString {
        attributed + AttributedString(string)
    }

    
}

extension NSAttributedString {
#if canImport(UIKit)
    convenience init(_ string: String, color: UIColor? = nil, font: UIFont? = nil) {
        var attributes: [NSAttributedString.Key : Any] = [:]
        
        if let color = color {
            attributes[NSAttributedString.Key.foregroundColor] = color
        }
        if let font = font {
            attributes[NSAttributedString.Key.font] = font
        }
        
        self.init(string: string, attributes: attributes)
    }

    convenience init(markdown string: String, font: UIFont? = nil) {
        let font = font ?? UIFont.systemFont(ofSize: 17)
        let tokens = ["@*/",
                      "**",
                      "//",
                      "@@",
                      "*/",
                      "@/",
                      "@*",
                      "^^"
                      ]
        let pointSize = font.fontDescriptor.pointSize
        let boldItalicFont = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits([.traitItalic, .traitBold])! , size: pointSize)
        let attributes: [[NSAttributedString.Key : Any]] = [
            [NSAttributedString.Key.foregroundColor: UIColor.red,
             NSAttributedString.Key.font: boldItalicFont],
            
            [NSAttributedString.Key.font : UIFont.systemFont(ofSize: pointSize, weight: .bold)],
            
            [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: pointSize)],
            
            [NSAttributedString.Key.foregroundColor: UIColor.red],
            
            [NSAttributedString.Key.font : boldItalicFont],
            
            [NSAttributedString.Key.foregroundColor: UIColor.red,
             NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: pointSize)],
            
            [NSAttributedString.Key.foregroundColor: UIColor.red,
             NSAttributedString.Key.font: UIFont.systemFont(ofSize: pointSize, weight: .bold)],
            
            [NSAttributedString.Key.foregroundColor: UIColor.red,
             NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24, weight: .bold)]
        ]
        self.init(attributedString: NSAttributedString.replace(in: string, tokens: tokens, with: attributes))
    }
    
    convenience init(imageName: String, color: UIColor? = nil) {
        let image = UIImage(prefixed: imageName)!
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = (color == nil ? image : image.asTemplate)
        let imageString = NSMutableAttributedString(attachment: imageAttachment)
        if let color = color {
            imageString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange(0...imageString.length - 1))
        }
        self.init(attributedString: imageString)
    }
    #endif
    
    private static func replace(in string: String, tokens: [String], with attributes: [[NSAttributedString.Key : Any]], level: Int = 0) -> NSAttributedString {
        var result = NSAttributedString()
        let part = string.components(separatedBy: tokens[level])
        for (index, substring) in part.enumerated() {
            if index % 2 == 0 {
                if level == tokens.count - 1 {
                    result = result + NSAttributedString(string: substring)
                } else {
                    result = result + replace(in: substring, tokens: tokens, with: attributes, level: level + 1)
                }
            } else {
                result = result + NSAttributedString(string: substring, attributes: attributes[level])
            }
        }
        return result
    }
    

    static func + (left: NSAttributedString, right: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(left)
        result.append(right)
        return result
    }

#if canImport(UIKit)
    static func ~= (left: inout NSAttributedString, right: String) {
        left = NSAttributedString(markdown: right)
    }
    
    static func + (left: NSAttributedString, right: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(left)
        result.append(NSAttributedString(markdown: right))
        return result
    }
    
    static func + (left: String, right: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(markdown: left))
        result.append(right)
        return result
    }
    
    func labelHeight(width: CGFloat? = nil, font: UIFont? = nil) -> CGFloat {
        let bboNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: width ?? CGFloat.greatestFiniteMagnitude, height: 1000))
        bboNameLabel.numberOfLines = (width == nil ? 1 : 0)
        if let font = font {
            bboNameLabel.font = font
        }
        bboNameLabel.lineBreakMode = .byWordWrapping
        bboNameLabel.attributedText = self
        bboNameLabel.sizeToFit()
        return bboNameLabel.frame.height
    }

    func labelWidth(height: CGFloat? = nil, font: UIFont? = nil) -> CGFloat {
        let bboNameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: height ?? 30))
        bboNameLabel.numberOfLines = (height == nil ? 1 : 0)
        if let font = font {
            bboNameLabel.font = font
        }
        bboNameLabel.attributedText = self
        bboNameLabel.sizeToFit()
        return bboNameLabel.frame.width
    }
    #endif
}

#if canImport(UIKit)
extension UIFont {
    
    var bold: UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitBold)
        return UIFont(descriptor: descriptor!, size: 0)
    }
    
    var italic: UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitItalic)
        return UIFont(descriptor: descriptor!, size: 0)
    }

}
#endif

extension NSMutableAttributedString {
    
    static func + (left: NSMutableAttributedString, right: NSMutableAttributedString) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        result.append(left)
        result.append(right)
        return result
    }
}

extension Float {
    func toString(places: Int, exact: Bool = false) -> String{
        let rounded = Utility.round(self, places: places)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = places
        if exact {
            formatter.minimumFractionDigits = places
        }
        let number = NSNumber(value: rounded)
        return formatter.string(from: number)!
    }
}

extension Decimal {
    func toString(places: Int) -> String{
        return "\(self)"
    }
}

extension Int {
    var sign: Int {
        return (self == 0 ? 0 : (self > 0 ? 1 : -1))
    }
}

extension View {
        /// Applies the given transform if the given condition evaluates to `true`.
        /// - Parameters:
        ///   - condition: The condition to evaluate.
        ///   - transform: The transform to apply to the source `View`.
        /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}

    
struct PaletteModifier : ViewModifier {
    var color: PaletteColor
    var textType: ThemeTextType = .normal
    
    func body(content: Content) -> some View { content
        .background(color.background)
        .foregroundColor(color.textColor(textType))
    }
}

extension View {
    func palette(_ color: ThemeBackgroundColorName, _ textType: ThemeTextType? = .normal) -> some View {
        self.modifier(PaletteModifier(color: PaletteColor(color), textType: textType ?? .normal))
    }
}
