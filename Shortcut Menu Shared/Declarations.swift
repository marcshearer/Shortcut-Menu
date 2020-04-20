//
//  Resources.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import SwiftUI

public enum EditMode: Int {
    case none = 0
    case create = 1
    case amend = 2
}

public enum EditObject: Int {
    case none = 0
    case section = 1
    case shortcut = 2
}

let rowHeight:CGFloat = 50.0
let sectionWidth: CGFloat = 200.0
let shortcutWidth: CGFloat = 300.0
let detailWidth: CGFloat = 400.0
let formHeight: CGFloat = 600.0

let defaultFont = Font.system(size: 20.0)

let listBackgroundColor = Color.clear
let listTextColor = Color.black
let listMessageColor = Color.gray

let sectionSelectionBackgroundColor = Color.blue
let sectionSelectionTextColor = Color.white
let sectionDefaultTextColor = Color.gray

let shortcutSelectionBackgroundColor = Color.blue
let shortcutSelectionTextColor = Color.white

let titleBackgroundColor = Color.gray
let titleTextColor = Color.white
