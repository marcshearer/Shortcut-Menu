//
//  AppDelegate.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // Cache main context for core data
        MasterData.context = PersistenceController.shared.container.viewContext
    
         // Build status menu
        StatusMenu.shared.update()
    }
}

