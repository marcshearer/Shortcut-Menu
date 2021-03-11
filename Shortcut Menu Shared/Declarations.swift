//
//  Declarations.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import SwiftUI

// Enumerations

public enum EditAction: Int {
    case none = 0
    case create = 1
    case amend = 2
}

public enum EditObject: Int {
    case none = 0
    case section = 1
    case shortcut = 2
}

// Sizes
let defaultRowHeight:CGFloat = (MyApp.target == .macOS ? 50.0 : 60.0)
let defaultSectionWidth: CGFloat = 200.0
let defaultShortcutWidth: CGFloat = 300.0
let defaultDetailWidth: CGFloat = 400.0
let defaultFormHeight: CGFloat = 600.0
let inputTopHeight: CGFloat = (MyApp.target == .macOS ? 10 : 30.0)
let inputDefaultHeight: CGFloat = 30.0
let bannerHeight: CGFloat = (MyApp.target == .macOS ? 60 : 70)

// Fonts
var defaultFont = Font.system(size: (MyApp.target == .macOS ? 20.0 : 28.0))
var captionFont = Font.system(size: (MyApp.target == .macOS ? 16.0 : 20.0))
var messageFont = Font.system(size: (MyApp.target == .macOS ? 12.0 : 16.0))

// Text for default section
let defaultSectionDisplayName = "Default Section"
let defaultSectionTitleName = "Default"
let defaultSectionMenuName = "Defaults only"
