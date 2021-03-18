//
//  MyApp.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 05/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import CloudKit
import CoreData
import SwiftUI
import AudioToolbox

enum UserDefault: String, CaseIterable {
    case currentSection

    public var name: String { "\(self)" }
    
    public var defaultValue: Any {
        switch self {
        case .currentSection:
            return ""
        }
    }
    
    public func set(_ value: Any) {
        UserDefaults.standard.set(value, forKey: self.name)
    }
    
    public var string: String {
        return UserDefaults.standard.string(forKey: self.name)!
    }
    
    public var int: Int {
        return UserDefaults.standard.integer(forKey: self.name)
    }
    
    public var bool: Bool {
        return UserDefaults.standard.bool(forKey: self.name)
    }
}

class MyApp {
    
    enum Target {
        case iOS
        case macOS
    }
    
    static let shared = MyApp()
        
    #if os(macOS)
    public static let target: Target = .macOS
    #else
    public static let target: Target = .iOS
    #endif
    
    public func start() {
        let container = PersistenceController.shared.container
        MasterData.context = container.viewContext
        MasterData.backgroundContext = container.newBackgroundContext()
        
        // Uncomment to backup / restore
        // Backup.shared/*.backup()*/.restore(dateString: "2021-03-15-17-21-46-381") ; sound()
        
        MasterData.shared.load()
        MasterData.purgeTransactionHistory()
        Themes.selectTheme(.standard)
        self.registerDefaults()
        
        #if canImport(UIKit)
        UITextView.appearance().backgroundColor = .clear
        UITextField.appearance().backgroundColor = .clear
        #endif
    }
    
    private func registerDefaults() {
        var initial: [String:Any] = [:]
        for value in UserDefault.allCases {
            initial[value.name] = value.defaultValue
        }
        UserDefaults.standard.register(defaults: initial)
    }
    
    private func sound() {
        #if canImport(AppKit)
        NSSound(named: "Ping")!.play()
        #else
        AudioServicesPlayAlertSound(SystemSoundID(1304))
        #endif
    }
}

enum ShortcutMenuError: Error {
    case invalidData
}
