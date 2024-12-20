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

// UUID for default section
let defaultUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

// Sizes
let defaultRowHeight:CGFloat = (MyApp.format == .tablet ? 60.0 : (MyApp.format == .phone ? 40 : 50.0))
let defaultSectionWidth: CGFloat = 200.0
let defaultShortcutWidth: CGFloat = 300.0
let defaultDetailWidth: CGFloat = 600.0
let defaultFormHeight: CGFloat = 700.0
let inputTopHeight: CGFloat = (MyApp.format == .tablet ? 30.0 : 10.0)
let inputDefaultHeight: CGFloat = 30.0
let inputToggleDefaultHeight: CGFloat = (MyApp.format == .tablet ? 30.0 : 16.0)
let bannerHeight: CGFloat = (MyApp.format == .tablet ? 70.0 : 50.0)
let minimumBannerHeight: CGFloat = 40.0
let bannerBottom: CGFloat = (MyApp.format == .tablet ? 20.0 : 10.0)
let slideInMenuRowHeight: CGFloat = (MyApp.target == .iOS ? 50 : 35)

// Fonts
var defaultFont = Font.system(size: (MyApp.format == .tablet ? 28.0 : 20.0))
var toolbarFont = Font.system(size: (MyApp.format == .tablet ? 16.0 : 12.0))
var captionFont = Font.system(size: (MyApp.format == .tablet ? 20.0 : 16.0))
var inputFont = Font.system(size: (MyApp.format == .tablet ? 16.0 : 12.0))
var messageFont = Font.system(size: (MyApp.format == .tablet ? 16.0 : 12.0))

// Text for default section
let defaultSectionDisplayName = "Default Section"
let defaultSectionTitleName = "Default"
let defaultSectionMenuName = "Defaults only"
let noDefaultSectionMenuName = "No Section"

// Cloud database
let iCloudIdentifier = "iCloud.ShearerOnline.Shortcuts"

// Backups
let backupDirectoryDateFormat = "yyyy-MM-dd-HH-mm-ss-SSS"
let backupDateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"

// Delay for opening directories
let directoryHoverDelay: TimeInterval = 0.75

