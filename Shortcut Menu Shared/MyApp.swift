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
    
    enum Database: String {
        case development = "Development"
        case production = "Production"
        case unknown = "Unknown"
        
        public var name: String {
            return self.rawValue
        }
    }
    
    static let shared = MyApp()
        
    /// Database to use - This  **MUST MUST MUST** match icloud entitlement
    static let expectedDatabase: Database = .production

    // Actual database found
    public static var database: Database = .unknown

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
        Utility.executeAfter(delay: 10) {
            Backup.shared.backup()/*.restore(dateString: "2023-03-06-08-12-15-014")*/ ; self.sound() ; Utility.executeAfter(delay: 1.5) { self.sound() ; Utility.executeAfter(delay: 1.5) { self.sound() }}
        }
        
        MasterData.shared.load()
        MasterData.purgeTransactionHistory()
        Themes.selectTheme(.standard)
        UserDefault.registerDefaults()
        Version.current.load()
        self.setupDatabase()
        
        #if canImport(UIKit)
        UITextView.appearance().backgroundColor = .clear
        UITextField.appearance().backgroundColor = .clear
        #endif
    }
    
    private func setupDatabase() {
        
        // Get saved database
        MyApp.database = Database(rawValue: UserDefault.database.string) ?? .unknown
        
        // Check which database we are connected to
        ICloud.shared.getDatabaseIdentifier { (success, errorMessage, database, minVersion, minMessage, infoMessage) in
            
            if success {
                Utility.mainThread {
                    
                    // Store database identifier
                    let cloudDatabase: Database = Database(rawValue: database ?? "") ?? .unknown
                    
                    if cloudDatabase != MyApp.expectedDatabase {
                        MessageBox.shared.show("Attached to the \(cloudDatabase.name) database but expected to be connected to the \(MyApp.expectedDatabase.name) database") { (_) in
                            exit(1)
                        }
                    }
                    
                    if MyApp.database != .unknown && MyApp.database != cloudDatabase {
                        MessageBox.shared.show("This device was connected to the \(MyApp.database) database and is now trying to connect to the \(cloudDatabase) database") { (_) in
                            exit(1)
                        }
                    }
                    
                    MyApp.database = cloudDatabase
                    UserDefault.database.set(cloudDatabase.name)
                    Version.current.set(minVersion: minVersion ?? "", minMessage: minMessage ?? "", infoMessage: infoMessage ?? "")
                }
            }
        }
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

extension UserDefaults {
    // Move user defaults to a suite on Mac non-production
    static var shared: UserDefaults {
        if MyApp.expectedDatabase != .production {
            return UserDefaults(suiteName: "com.sheareronline.\(MyApp.expectedDatabase.name)")!
        } else {
            return UserDefaults.standard
        }
    }
}
