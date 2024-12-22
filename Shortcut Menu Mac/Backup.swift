//
//  Backup.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 15/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import CoreData
#if canImport(AppKit)
import AppKit
#endif
import CloudKit

class Backup {
    
    public static let shared = Backup()
    
    public func backup() {
        let fileManager = FileManager()
        let (backupsUrl, assetsBackupUrl) = self.getDirectories()
        let databaseBackupsUrl = backupsUrl.appendingPathComponent(UserDefault.database.string)
        let dateString = Utility.dateString(Date(), format: backupDirectoryDateFormat, localized: false)
        let thisBackupUrl = databaseBackupsUrl.appendingPathComponent(dateString)
        _ = (try! fileManager.createDirectory(at: thisBackupUrl, withIntermediateDirectories: true))
        _ = (try! fileManager.createDirectory(at: assetsBackupUrl, withIntermediateDirectories: true))

        Backup.shared.backup(entity: SectionMO.entity(), groupName: "data", elementName: "Sections", directory: thisBackupUrl, assetsDirectory: assetsBackupUrl)
        Backup.shared.backup(entity: ShortcutMO.entity(), groupName: "data", elementName: "Shortcuts", directory: thisBackupUrl, assetsDirectory: assetsBackupUrl)
        Backup.shared.backup(entity: CloudSectionMO.entity(), groupName: "data", elementName: "CloudSections", directory: thisBackupUrl, assetsDirectory: assetsBackupUrl)
        Backup.shared.backup(entity: CloudShortcutMO.entity(), groupName: "data", elementName: "CloudShortcuts", directory: thisBackupUrl, assetsDirectory: assetsBackupUrl)
        Backup.shared.backup(entity: ReplacementMO.entity(), groupName: "data", elementName: "Replacements", directory: thisBackupUrl, assetsDirectory: assetsBackupUrl)
    }
    
    public func restore(dateString: String) {
        let (backupsUrl, assetsBackupUrl) = self.getDirectories()
        let databaseBackupsUrl = backupsUrl.appendingPathComponent(UserDefault.database.string)
        let thisBackupUrl = databaseBackupsUrl.appendingPathComponent(dateString)
        
        Backup.shared.restore(directory: thisBackupUrl, assetsDirectory: assetsBackupUrl, entity: SectionMO.entity(), groupName: "data", elementName: "Sections")
        Backup.shared.restore(directory: thisBackupUrl, assetsDirectory: assetsBackupUrl, entity: ShortcutMO.entity(), groupName: "data", elementName: "Shortcuts")
        Backup.shared.restore(directory: thisBackupUrl, assetsDirectory: assetsBackupUrl, entity: CloudSectionMO.entity(), groupName: "data", elementName: "CloudSections")
        Backup.shared.restore(directory: thisBackupUrl, assetsDirectory: assetsBackupUrl, entity: CloudShortcutMO.entity(), groupName: "data", elementName: "CloudShortcuts")
        Backup.shared.restore(directory: thisBackupUrl, assetsDirectory: assetsBackupUrl, entity: ReplacementMO.entity(), groupName: "data", elementName: "Replacements")
    }
    
    private func getDirectories() -> (URL, URL) {
        let documentsUrl:URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last! as URL
        let backupsUrl = documentsUrl.appendingPathComponent("backups")
        let assetsBackupUrl = backupsUrl.appendingPathComponent("assets")
        return (backupsUrl, assetsBackupUrl)
    }
    
    private func backup(entity: NSEntityDescription, groupName: String, elementName: String, sort: [(key: String, ascending: Bool)] = [], directory: URL, assetsDirectory: URL) {
        var records = 0
        
        let recordType = entity.name!
        if let fileHandle = openFile(directory: directory, recordType: recordType) {
            self.writeString(fileHandle: fileHandle, string: "{ \"\(groupName)\" : [\n")
            
            let recordList = MasterData.fetch(from: recordType, sort: sort)
            for record in recordList {
                records += 1
                if records > 1 {
                    self.writeString(fileHandle: fileHandle, string: ",\n")
                }
                self.writeString(fileHandle: fileHandle, string: "     { \"\(elementName)\" : ")
                if !self.writeRecord(fileHandle: fileHandle, assetsDirectory: assetsDirectory, elementName: elementName, record: record) {
                    fatalError("Error writing record")
                }
                self.writeString(fileHandle: fileHandle, string: "\n     }")
            }
            self.writeString(fileHandle: fileHandle, string: "\n     ]")
            self.writeString(fileHandle: fileHandle, string: "\n}")
            fileHandle.closeFile()
        }
    }
    
    private func restore(directory: URL, assetsDirectory: URL, entity: NSEntityDescription, groupName: String, elementName: String) {
        
        let recordType = entity.name!
        self.initialise(recordType: recordType)
        let fileURL = directory.appendingPathComponent("\(recordType).json")
        let fileContents = try! Data(contentsOf: fileURL, options: [])
        let fileDictionary = try! JSONSerialization.jsonObject(with: fileContents, options: []) as! [String:Any?]
        let contents = fileDictionary[groupName] as! [[String:Any?]]
        
        for record in contents {
            let keys = record[elementName] as! [String:Any]
            
            let record = NSManagedObject(entity: entity, insertInto: MasterData.context)
            for (keyName, _) in keys {
                if let actualValue = self.value(forKey: keyName, keys: keys, assetsDirectory: assetsDirectory) {
                    record.setValue(actualValue, forKey: keyName)
                } else {
                    fatalError("Error in \(recordType) - Invalid key value for \(keyName)")
                }
            }
        }
        try! MasterData.context.save()
    }
    
    private func initialise(recordType: String) {
        let records = MasterData.fetch(from: recordType)
        for record in records {
            MasterData.context.delete(record)
            try! MasterData.context.save()
        }
    }
    
    private func value(forKey name: String, keys: [String:Any], assetsDirectory: URL) -> Any? {
        var result: Any?
        if let specialValue = keys[name] as? [String:String] {
            // Special value
            if specialValue.keys.first == "date" {
                result = Utility.dateFromString(specialValue["date"]!, format: backupDateFormat, localized: false)
            } else if specialValue.keys.first == "uuid" {
                result = UUID(uuidString: specialValue["uuid"]!)
            } else if specialValue.keys.first == "data" {
                result = Data(base64Encoded: specialValue["data"] ?? "")
            } else if specialValue.keys.first == "asset" {
                let assetDescriptor = specialValue["asset"]!
                let assetUrl = assetsDirectory.appendingPathComponent(assetDescriptor).appendingPathExtension("jpeg")
                result = CKAsset(fileURL: assetUrl)
            }
        } else {
            result = keys[name]
        }
        return result
    }
    
    private func openFile(directory: URL, recordType: String) -> FileHandle! {
        var fileHandle: FileHandle!
        
        let fileUrl =  directory.appendingPathComponent("\(recordType).json")
        let fileManager = FileManager()
        fileManager.createFile(atPath: fileUrl.path, contents: nil)
        fileHandle = FileHandle(forWritingAtPath: fileUrl.path)
        
        return fileHandle
    }
    
    private func writeRecord(fileHandle: FileHandle, assetsDirectory: URL, elementName: String, record: NSManagedObject) -> Bool {
        // Build a dictionary from the record
        var dictionary: [String : Any] = [:]
        
        for (key, _) in record.entity.attributesByName {
            let value = record.value(forKey: key)
            if value == nil {
                // No need to back up
            } else if let date = value! as? Date {
                dictionary[key] = ["date" : Utility.dateString(date, format: backupDateFormat, localized: false)]
            } else if let uuid = value! as? UUID {
                dictionary[key] = ["uuid" : uuid.uuidString]
            } else if let data = value! as? Data {
                dictionary[key] = ["data" : data.base64EncodedString()]
            } else if let asset = value as? CKAsset {
#if canImport(AppKit)
                if let data = try? Data.init(contentsOf: asset.fileURL!) {
                    let imageFileURL = assetsDirectory.appendingPathComponent(record.objectID.uriRepresentation().absoluteString).appendingPathExtension("jpeg")
                    if (try? FileManager.default.removeItem(at: imageFileURL)) == nil {
                        // Ignore
                    }
                    if let bits = NSImage(data: data as Data)!.representations.first as? NSBitmapImageRep {
                        let data = bits.representation(using: .jpeg, properties: [:])
                        do {
                            if (((try! data?.write(to: imageFileURL)) as ()??)) != nil {
                                dictionary[key] = ["asset" : record.objectID.uriRepresentation().absoluteString]
                                continue
                            }
                        }
                    }
                }
#endif
               // Failed - just insert and will probably crash
                dictionary[key] = value!
            } else {
                dictionary[key] = value!
            }
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary)
            fileHandle.write(data)
        } catch {
            // error
            return false
        }
        return true
    }
    
    private func writeString(fileHandle: FileHandle, string: String) {
        let data = string.data(using: .utf8)!
        fileHandle.write(data)
    }
    
    public func errorMessage(_ error: Error?) -> String {
        if error == nil {
            return "Success"
        } else {
            return "Error updating (\(error!.localizedDescription))"
        }
    }
    
}
