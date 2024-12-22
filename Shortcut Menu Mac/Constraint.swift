//
//  Constraint.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 20/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

#if os(macOS)
import Cocoa
#else
import UIKit
#endif

enum ConstraintAnchor: CustomStringConvertible {
    case leading
    case trailing
    case top
    case bottom
    case all
    case horizontal
    case vertical
    case centerX
    case centerY
    case safeLeading
    case safeTrailing
    case safeTop
    case safeBottom
    case safeAll
    case safeHorizontal
    case safeVertical
    
    var safe: Bool {
        return self == .safeLeading || self == .safeTrailing || self == .safeTop || self == .safeBottom || self == .safeAll || self == .safeHorizontal || self == .safeVertical
    }
    
    var description: String {
        switch self {
        case .leading, .safeLeading:
            return ".leading"
        case .trailing, .safeTrailing:
            return ".trailing"
        case .top, .safeTop:
            return ".top"
        case .bottom, .safeBottom:
            return ".bottom"
        case .all, .safeAll:
            return ".all"
        case .horizontal, .safeHorizontal:
            return ".horizontal"
        case .vertical, .safeVertical:
            return ".vertical"
        case .centerX:
            return ".centerX"
        case .centerY:
            return ".centerY"
        }
    }

    var constraint: NSLayoutConstraint.Attribute {
        switch self {
        case .leading, .safeLeading:
            return .leading
        case .trailing, .safeTrailing:
            return .trailing
        case .top, .safeTop:
            return .top
        case .bottom, .safeBottom:
            return .bottom
        case .all, .safeAll, .horizontal, .safeHorizontal, .vertical, .safeVertical:
            fatalError("Not supported")
        case .centerX:
            return .centerX
        case .centerY:
            return .centerY
        }
    }
    
    var expanded: [ConstraintAnchor] {
        switch self {
        case .horizontal:
            return [.leading, .trailing]
        case .vertical:
            return [.top, .bottom]
        case .all:
            return [.leading, .trailing, .top, .bottom]
        case .safeAll:
            return [.safeLeading, .safeTrailing, .safeTop, .safeBottom]
        case .safeHorizontal:
            return [.safeLeading, .safeTrailing]
        case .safeVertical:
            return [.safeTop, .safeBottom]
        default:
            return [self]
        }
    }
    
    var opposite: ConstraintAnchor? {
        switch self {
        case .leading:
            return .trailing
        case .trailing:
            return .leading
        case .top:
            return .bottom
        case .bottom:
            return .top
        case .safeLeading:
            return .safeTrailing
        case .safeTrailing:
            return .safeLeading
        case .safeTop:
            return .safeBottom
        case .safeBottom:
            return .safeTop
        case .all, .safeAll, .horizontal, .safeHorizontal, .vertical, .safeVertical:
            return nil
        case .centerX:
            return .centerX
        case .centerY:
            return .centerY
        }
    }
}

class Constraint {
    
    public static func setWidth(control: NSView, width: CGFloat) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: control, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: width)
        control.addConstraint(constraint)
        return constraint
    }
    
    public static func setHeight(control: NSView, height: CGFloat) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: control, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: height)
        control.addConstraint(constraint)
        return constraint
    }
    
    @discardableResult public static func anchor(view: NSView, control: NSView, to: NSView? = nil, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0, toAttribute: ConstraintAnchor? = nil, priority: NSLayoutConstraint.Priority = .required, attributes: ConstraintAnchor...) -> [NSLayoutConstraint] {
        
        Constraint.anchor(view: view, control: control, to: to, multiplier: multiplier, constant: constant, toAttribute: toAttribute, priority: priority, attributes: attributes)
    }

    @discardableResult public static func anchor(view: NSView, control: NSView, to: NSView? = nil, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0, toAttribute: ConstraintAnchor? = nil, priority: NSLayoutConstraint.Priority = .required, attributes anchorAttributes: [ConstraintAnchor]) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        let anchorAttributes = (anchorAttributes.count == 0 ? [.all] : anchorAttributes)
        var attributes: [ConstraintAnchor] = []
        for attribute in anchorAttributes {
            attributes.append(contentsOf: attribute.expanded)
        }
        let to = to ?? view
        control.translatesAutoresizingMaskIntoConstraints = false
        for attribute in attributes {
            let toAttribute = toAttribute ?? attribute
            let control = attribute.safe ? control.safeAreaLayoutGuide : control
            let to = toAttribute.safe ? to.safeAreaLayoutGuide : to
            let sign: CGFloat = (attribute == .trailing || attribute == .bottom ? -1.0 : 1.0)
            let constraint = NSLayoutConstraint(item: control, attribute: attribute.constraint, relatedBy: .equal, toItem: to, attribute: toAttribute.constraint, multiplier: multiplier, constant: constant * sign)
            constraint.priority = priority
            view.addConstraint(constraint)
            constraints.append(constraint)
        }
        return constraints
    }
}

extension NSView {
    
    func addSubview(_ parent: NSView, constant: CGFloat = 0, anchored attributes: ConstraintAnchor...) {
        self.addSubview(parent)
        Constraint.anchor(view: self, control: parent, constant: constant, attributes: attributes)
    }
    
    func addSubview(_ parent: NSView, constant: CGFloat = 0, anchored attributes: [ConstraintAnchor]?) {
        self.addSubview(parent)
        if let attributes = attributes {
            Constraint.anchor(view: self, control: parent, constant: constant, attributes: attributes)
        }
    }
    
    func addSubview(_ parent: NSView, leading: CGFloat? = nil, trailing: CGFloat? = nil, top: CGFloat? = nil, bottom: CGFloat? = nil) {
        self.addSubview(parent)
        if let leading = leading {
            Constraint.anchor(view: self, control: parent, constant: leading, attributes: .leading)
        }
        if let trailing = trailing {
            Constraint.anchor(view: self, control: parent, constant: trailing, attributes: .trailing)
        }
        if let top = top {
            Constraint.anchor(view: self, control: parent, constant: top, attributes: .top)
        }
        if let bottom = bottom {
            Constraint.anchor(view: self, control: parent, constant: bottom, attributes: .bottom)
        }
    }
    
}
