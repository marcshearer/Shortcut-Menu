//
//  Persistence.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 09/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import CoreData
import SwiftUI

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Setup preview data
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return result
    }()

    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Shortcut_Menu")
        Utility.debugMessage("Log",container.persistentStoreCoordinator.persistentStores.debugDescription)

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            
            // Get core data directory and append Development or Production
            let storeDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            
            // Create a store description for a local store
            let localStoreLocation = storeDirectory.appendingPathComponent("ShortcutLocal-\(MyApp.expectedDatabase.name).sqlite")
            
            let localStoreDescription =
                NSPersistentStoreDescription(url: localStoreLocation)
            localStoreDescription.configuration = "Local"
            
            // Create a store description for a CloudKit-backed local store
            let cloudStoreLocation = storeDirectory.appendingPathComponent("ShortcutCloud-\(MyApp.expectedDatabase.name).sqlite")
            let cloudStoreDescription =
                NSPersistentStoreDescription(url: cloudStoreLocation)
            // Set the container ID on the cloud store
            cloudStoreDescription.cloudKitContainerOptions =
                NSPersistentCloudKitContainerOptions(
                    containerIdentifier: "iCloud.ShearerOnline.Shortcuts")
            cloudStoreDescription.configuration = "Cloud"
            // Flag remote changes
            let remoteChangeKey = "NSPersistentStoreRemoteChangeNotificationOptionKey"
            cloudStoreDescription.setOption(true as NSNumber, forKey: remoteChangeKey)
            cloudStoreDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            
            // Set the container options on the cloud store
            cloudStoreDescription.cloudKitContainerOptions =
                NSPersistentCloudKitContainerOptions(
                    containerIdentifier: "iCloud.ShearerOnline.Shortcuts")
            
            // Update the container's list of store descriptions
            container.persistentStoreDescriptions = [
                cloudStoreDescription,
                localStoreDescription
            ]
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        if !inMemory {
            // Merge
            container.viewContext.automaticallyMergesChangesFromParent = true
        }
    }
}
