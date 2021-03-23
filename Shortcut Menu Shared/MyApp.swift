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
    case database
    case lastVersion
    case lastBuild
    case minVersion
    case minMessage
    case infoMessage
    
    public var name: String { "\(self)" }
    
    public var defaultValue: Any {
        switch self {
        case .currentSection:
            return ""
        case .database:
            return "unknown"
        case .lastVersion:
            return "0.0"
        case .lastBuild:
            return 0
        case .minVersion:
            return 0
        case .minMessage:
            return ""
        case .infoMessage:
            return ""}
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
    
    enum Format {
        case computer
        case tablet
        case phone
    }
    
    static let shared = MyApp()
        
    public static var database: String = "unknown"

    #if os(macOS)
    public static let target: Target = .macOS
    #else
    public static let target: Target = .iOS
    #endif
    
    public static var format: Format = .computer
        
    public func start() {
        let container = PersistenceController.shared.container
        MasterData.context = container.viewContext
        MasterData.backgroundContext = container.newBackgroundContext()
        
        // Uncomment to backup / restore
        // Backup.shared.backup()/*.restore(dateString: "2021-03-15-17-21-46-381")*/ ; sound() ; Utility.executeAfter(delay: 1.5) { self.sound() ; Utility.executeAfter(delay: 1.5) { self.sound() }}
        
        MasterData.shared.load()
        MasterData.purgeTransactionHistory()
        Themes.selectTheme(.standard)
        self.registerDefaults()
        Version.current.load()
        self.setupDatabase()
        
        #if canImport(UIKit)
        UITextView.appearance().backgroundColor = .clear
        UITextField.appearance().backgroundColor = .clear
        #endif
    }
    
    private func setupDatabase() {
        
        // Get saved database
        MyApp.database = UserDefault.database.string
        
        // Check which database we are connected to
        ICloud.shared.getDatabaseIdentifier { (success, errorMessage, database, minVersion, minMessage, infoMessage) in
            
            if success {
                Utility.mainThread {
                    
                    // Store database identifier
                    let cloudDatabase = database ?? "unknown"
                    if MyApp.database != "unknown" && MyApp.database != cloudDatabase {
                        MessageBox.shared.show("This device was connected to the \(MyApp.database) database and is now trying to connect to the \(cloudDatabase) database") {
                            exit(1)
                        }
                    }
                    
                    MyApp.database = cloudDatabase
                    UserDefault.database.set(cloudDatabase)
                    Version.current.set(minVersion: minVersion ?? "", minMessage: minMessage ?? "", infoMessage: infoMessage ?? "")
                }
            }
        }
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
