//
//  iCloud.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 22/07/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Foundation
import CloudKit
import Cocoa

class ICloud {
    
    private var cancelRequest = false
    
    public func cancel() {
        self.cancelRequest = true
    }
    
    public func download(recordType: String,
                         database: CKDatabase? = nil,
                         keys: [String]! = nil,
                         sortKey: [String]! = nil,
                         sortAscending: Bool! = true,
                         predicate: NSPredicate = NSPredicate(value: true),
                         resultsLimit: Int! = nil,
                         downloadAction: ((CKRecord) -> ())? = nil,
                         completeAction: (() -> ())? = nil,
                         failureAction:  ((Error?) -> ())? = nil,
                         cursor: CKQueryOperation.Cursor! = nil,
                         rowsRead: Int = 0) {
        
        var queryOperation: CKQueryOperation
        var rowsRead = rowsRead
        // Clear cancel flag
        self.cancelRequest = false
        
        // Fetch player records from cloud
        let cloudContainer = CKContainer(identifier: Config.iCloudIdentifier)
        let database = database ?? cloudContainer.publicCloudDatabase
        if cursor == nil {
            // First time in - set up the query
            let query = CKQuery(recordType: recordType, predicate: predicate)
            if sortKey != nil {
                var sortDescriptor: [NSSortDescriptor] = []
                for sortKeyElement in sortKey {
                    sortDescriptor.append(NSSortDescriptor(key: sortKeyElement, ascending: sortAscending ?? true))
                }
                query.sortDescriptors = sortDescriptor
            }
            queryOperation = CKQueryOperation(query: query)
        } else {
            // Continue previous query
            queryOperation = CKQueryOperation(cursor: cursor)
        }
        queryOperation.desiredKeys = keys
        queryOperation.queuePriority = .veryHigh
        queryOperation.qualityOfService = .userInteractive
        queryOperation.resultsLimit = (resultsLimit != nil ? resultsLimit : (rowsRead < 100 ? 20 : 100))
        queryOperation.recordFetchedBlock = { (record) -> Void in
            Utility.mainThread {
                let cloudObject: CKRecord = record
                rowsRead += 1
                downloadAction?(cloudObject)
            }
        }
        
        queryOperation.queryCompletionBlock = { (cursor, error) -> Void in
            Utility.mainThread {
                
                if error != nil {
                    failureAction?(error)
                    return
                }
                
                if cursor != nil && !self.cancelRequest && (resultsLimit == nil || rowsRead < resultsLimit) {
                    // More to come - recurse
                    self.download(recordType: recordType,
                                      database: database,
                                      keys: keys,
                                      sortKey: sortKey,
                                      sortAscending: sortAscending,
                                      predicate: predicate,
                                      resultsLimit: resultsLimit,
                                      downloadAction: downloadAction,
                                      completeAction: completeAction,
                                      failureAction: failureAction,
                                      cursor: cursor, rowsRead: rowsRead)
                } else {
                    completeAction?()
                }
            }
        }
        
        // Execute the query - disable
        database.add(queryOperation)
    }
    
    public func update(records: [CKRecord]? = nil, recordIDsToDelete: [CKRecord.ID]? = nil, database: CKDatabase? = nil, recordsRemainder: [CKRecord]? = nil, recordIDsToDeleteRemainder: [CKRecord.ID]? = nil, completion: ((Error?)->())? = nil) {
        // Copes with limit being exceeed which splits the load in two and tries again
        var lastSplit = 400
        
        if (records?.count ?? 0) + (recordIDsToDelete?.count ?? 0) > lastSplit {
            // No point trying - split immediately
            lastSplit = self.updatePortion(database: database, requireLess: true, lastSplit: lastSplit, records: records, recordIDsToDelete: recordIDsToDelete, recordsRemainder: recordsRemainder, recordIDsToDeleteRemainder: recordIDsToDeleteRemainder, completion: completion)
        } else {
            // Give it a go
            let cloudContainer = CKContainer.init(identifier: Config.iCloudIdentifier)
            let database = database ?? cloudContainer.publicCloudDatabase
            
            let uploadOperation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: recordIDsToDelete)
            
            uploadOperation.isAtomic = true
            uploadOperation.database = database
            uploadOperation.qualityOfService = .userInteractive
            
            // Assign a completion handler
            uploadOperation.modifyRecordsCompletionBlock = { (savedRecords: [CKRecord]?, deletedRecords: [CKRecord.ID]?, error: Error?) -> Void in

                Utility.mainThread {
                    
                    if error != nil {
                        if let error = error as? CKError {
                            if error.code == .limitExceeded {
                                // Limit exceeded - start at 400 and then split in two and try again
                                lastSplit = self.updatePortion(database: database, requireLess: true, lastSplit: lastSplit, records: records, recordIDsToDelete: recordIDsToDelete, recordsRemainder: recordsRemainder, recordIDsToDeleteRemainder: recordIDsToDeleteRemainder, completion: completion)
                            } else if error.code == .partialFailure {
                                /*if let dictionary = error.userInfo[CKPartialErrorsByItemIDKey] as? NSDictionary {
                                    print("partialErrors \(dictionary)")
                                }*/
                                completion?(error)
                            } else {
                                completion?(error)
                            }
                        } else {
                            completion?(error)
                        }
                    } else {
                        if recordsRemainder != nil || recordIDsToDeleteRemainder != nil {
                            // Now need to send next block of records
                            lastSplit = self.updatePortion(database: database, requireLess: false, lastSplit: lastSplit, records: nil, recordIDsToDelete: nil, recordsRemainder: recordsRemainder, recordIDsToDeleteRemainder: recordIDsToDeleteRemainder, completion: completion)
                            
                        } else {
                            completion?(nil)
                        }
                    }
                }
            }
            
            // Add the operation to an operation queue to execute it
            OperationQueue().addOperation(uploadOperation)
        }
    }
    
    private func updatePortion(database: CKDatabase?, requireLess: Bool, lastSplit: Int, records: [CKRecord]?, recordIDsToDelete: [CKRecord.ID]?, recordsRemainder: [CKRecord]?, recordIDsToDeleteRemainder: [CKRecord.ID]?, completion: ((Error?)->())?) -> Int {
        
        // Limit exceeded - start at 400 and then split in two and try again

        // Join records and remainder back together again
        var allRecords = records ?? []
        if recordsRemainder != nil {
            allRecords += recordsRemainder!
        }
        var allRecordIDsToDelete = recordIDsToDelete ?? []
        if recordIDsToDeleteRemainder != nil {
            allRecordIDsToDelete += recordIDsToDeleteRemainder!
        }

        var split = lastSplit
        let firstTime = (recordsRemainder == nil && recordIDsToDeleteRemainder == nil)
        if requireLess {
            if allRecords.count != 0 {
                // Split the records
                let half = Int((records?.count ?? 0) / 2)
                split = (firstTime ? lastSplit : half)
            } else {
                // Split the record IDs to delete
                let half = Int((recordIDsToDelete?.count ?? 0) / 2)
                split = (firstTime ? lastSplit : half)
            }
        } else {
            split = lastSplit
        }
        
        // Now split at new break point
        if allRecords.count != 0 {
            split = min(split, allRecords.count)
            let firstBlock = Array(allRecords.prefix(upTo: split))
            let secondBlock = (allRecords.count <= split ? nil : Array(allRecords.suffix(from: split)))
            self.update(records: firstBlock, database: database, recordsRemainder: secondBlock, recordIDsToDeleteRemainder: allRecordIDsToDelete, completion: completion)
        } else {
            split = min(split, allRecordIDsToDelete.count)
            let firstBlock = Array(allRecordIDsToDelete.prefix(upTo: split))
            let secondBlock = (allRecordIDsToDelete.count <= split ? nil : Array(allRecordIDsToDelete.suffix(from: split)))
            self.update(recordIDsToDelete: firstBlock, database: database, recordIDsToDeleteRemainder: secondBlock, completion: completion)
        }
        
        return split
    }

    public func initialise(recordType: String, database: CKDatabase? = nil, completion: @escaping (Error?)->()) {
        var recordIDsToDelete: [CKRecord.ID] = []
        
        let cloudContainer = CKContainer.init(identifier: Config.iCloudIdentifier)
        let publicDatabase = cloudContainer.publicCloudDatabase
        let database = database ?? publicDatabase
        
        self.download(recordType: recordType, database: database, downloadAction: { (record) in
            recordIDsToDelete.append(record.recordID)
        },
        completeAction: {
            self.update(records: nil, recordIDsToDelete: recordIDsToDelete, database: database) { (error) in
                completion(error)
            }
        },
        failureAction: { (error) in
            completion(error)
        })
    }
    
    public func backup(recordType: String, groupName: String, elementName: String, sortKey: [String]? = nil, sortAscending: Bool? = nil, directory: URL, assetsDirectory: URL, completion: @escaping (Bool, String)->()) {
        var records = 0
        var errorMessage = ""
        var ok = true
        
        if let fileHandle = openFile(directory: directory, recordType: recordType) {
            self.writeString(fileHandle: fileHandle, string: "{ \"\(groupName)\" : [\n")
            self.download(recordType: recordType,
                              sortKey: sortKey,
                              sortAscending: sortAscending,
                              downloadAction: { (record) in
                                records += 1
                                if records > 1 {
                                    self.writeString(fileHandle: fileHandle, string: ",\n")
                                }
                                self.writeString(fileHandle: fileHandle, string: "     { \"\(elementName)\" : ")
                                if !self.writeRecord(fileHandle: fileHandle, assetsDirectory: assetsDirectory, elementName: elementName, record: record) {
                                    errorMessage = "Error writing record"
                                    ok = false
                                }
                                self.writeString(fileHandle: fileHandle, string: "\n     }")
            },
                              completeAction: {
                                self.writeString(fileHandle: fileHandle, string: "\n     ]")
                                self.writeString(fileHandle: fileHandle, string: "\n}")
                                fileHandle.closeFile()
                                completion(ok, (ok ? "Successfully backed up \(records) \(recordType)" : (errorMessage != "" ? errorMessage : "Unexpected error")))
            },
                              failureAction: { (error) in
                                fileHandle.closeFile()
                                errorMessage = "Error downloading \(recordType) (\(self.errorMessage(error)))"
                                completion(false, errorMessage)
            })
        } else {
            completion(false, "Error creating backup file")
        }
    }
    
    public func restore(directory: URL, assetsDirectory: URL, recordType: String, groupName: String, elementName: String, completion: @escaping (Bool, String)->()) {
        var records: [CKRecord] = []
        
        self.initialise(recordType: recordType) { (error) in
            let fileURL = directory.appendingPathComponent("\(recordType).json")
            do {
                let fileContents = try Data(contentsOf: fileURL, options: [])
                let fileDictionary = try JSONSerialization.jsonObject(with: fileContents, options: []) as! [String:Any?]
                let contents = fileDictionary[groupName] as! [[String:Any?]]
                
                for record in contents {
                    let keys = record[elementName] as! [String:Any]
                    
                    // Construct record ID
                    var recordID = recordType
                    for column in Config.recordIdKeys[recordType]! {
                        recordID += "+"
                        let value = self.value(forKey: column, keys: keys, assetsDirectory: assetsDirectory)
                        if let date = value as? Date {
                            recordID += Utility.dateString(date, format: Config.recordIdDateFormat, localized: false)
                        } else if value == nil {
                            if column.right(10).lowercased() == "playeruuid" {
                                // Might not have them yet - TODO remove after go live
                                recordID += UUID().uuidString
                            } else {
                                recordID += "NULL"
                            }
                        } else {
                            recordID += value as! String
                        }
                    }
                    
                    var errors = false
                    let cloudObject = CKRecord(recordType: recordType, recordID: CKRecord.ID(recordName: recordID))
                    for (keyName, _) in keys {
                        if recordType == "Version" && keyName == "database" {
                            // Database flag - do not overwrite
                            cloudObject.setValue(Utility.appDelegate!.database, forKey: keyName)
                        } else {
                            if let actualValue = self.value(forKey: keyName, keys: keys, assetsDirectory: assetsDirectory) {
                                cloudObject.setValue(actualValue, forKey: keyName)
                            } else {
                                completion(false, "Error in \(recordType) - Invalid key value for \(keyName) in \(recordID)")
                                errors = true
                                break
                            }
                        }
                    }
                    if errors {
                        break
                    } else {
                        records.append(cloudObject)
                    }
                }
                if !records.isEmpty {
                    Utility.mainThread {
                        if error != nil {
                            completion(false, self.errorMessage(error))
                        } else {
                            self.update(records: records) { (error) in
                                Utility.mainThread {
                                    if error == nil {
                                        completion(true, "\(records.count) records updated")
                                    } else {
                                        completion(false, self.errorMessage(error))
                                    }
                                }
                            }
                        }
                    }
                } else {
                    completion(true, "No records to update")
                }
            } catch let error as NSError {
                completion(false, "Error opening \(recordType) in backup \(error.localizedDescription)")
            }
        }
    }
    
    private func value(forKey name: String, keys: [String:Any], assetsDirectory: URL) -> Any? {
        var result: Any?
        if let specialValue = keys[name] as? [String:String] {
            // Special value
            if specialValue.keys.first == "date" {
                result = Utility.dateFromString(specialValue["date"]!, format: Config.backupDateFormat, localized: false)
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
    
    public func getPlayerUUIDs(completion: @escaping ([String:String]?)->()) {
        // Build cross refs for any existing player UUIDs and update players with any that are missing
        var emails: [String:String] = [:]
        
        self.download(recordType: "players",
        downloadAction: { (record) in
            // Add to xref
            if let email = record.value(forKey: "email") as? String,
                let playerUUID = record.value(forKey: "playerUUID") as? String {
                if playerUUID != "" {
                    emails[playerUUID] = email
                }
            }
        },
        completeAction: {
            completion(emails)
        },
        failureAction: { (error) in
            completion(nil)
        })
    }
    
    public func getDatabaseIdentifier(completion: @escaping (Bool, String?, String?)->()) {
        var database: String!
        
        self.download(recordType: "Version",
                          downloadAction: { (record) in
                                database = Utility.objectString(cloudObject: record, forKey: "database")
                          },
                          completeAction: {
                                completion(true, nil, database)
                          },
                          failureAction: { (error) in
                            completion(false, "Error downloading version \(self.errorMessage(error))", nil)
                          })
    }
    
    private func openFile(directory: URL, recordType: String) -> FileHandle! {
        var fileHandle: FileHandle!
        
        let fileUrl =  directory.appendingPathComponent("\(recordType).json")
        let fileManager = FileManager()
        fileManager.createFile(atPath: fileUrl.path, contents: nil)
        fileHandle = FileHandle(forWritingAtPath: fileUrl.path)
        
        return fileHandle
    }
    
    private func writeRecord(fileHandle: FileHandle, assetsDirectory: URL, elementName: String, record: CKRecord) -> Bool {
        // Build a dictionary from the record
        var dictionary: [String : Any] = [:]
        
        for key in record.allKeys() {
            let value = record.object(forKey: key)
            if value == nil {
                // No need to back up
            } else if let date = value! as? Date {
                dictionary[key] = ["date" : Utility.dateString(date, format: Config.backupDateFormat, localized: false)]
            } else if let asset = value as? CKAsset {
                if let data = try? Data.init(contentsOf: asset.fileURL!) {
                    let imageFileURL = assetsDirectory.appendingPathComponent(record.recordID.recordName).appendingPathExtension("jpeg")
                    if (try? FileManager.default.removeItem(at: imageFileURL)) == nil {
                        // Ignore
                    }
                    if let bits = NSImage(data: data as Data)!.representations.first as? NSBitmapImageRep {
                        let data = bits.representation(using: .jpeg, properties: [:])
                        do {
                            if (((try? data?.write(to: imageFileURL)) as ()??)) != nil {
                                dictionary[key] = ["asset" : record.recordID.recordName]
                                continue
                            }
                        }
                    }
                }
                // Failed - just insert and will probably crash
                dictionary[key] = value!
            } else {
                dictionary[key] = value!
            }
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary) else {
            // error
            return false
        }
        fileHandle.write(data)
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
            if let ckError = error as? CKError {
                return "Error updating (\(ckError.localizedDescription))"
            } else {
                return "Error updating (\(error!.localizedDescription))"
            }
        }
    }
    
    public func recordID(from record: CKRecord) -> CKRecord.ID {
        var recordID = record.recordType
        for column in Config.recordIdKeys[record.recordType]! {
            recordID += "+"
            let value = record.value(forKey: column)
            if let date = value as? Date {
                recordID += Utility.dateString(date, format: Config.recordIdDateFormat, localized: false)
            } else if value == nil {
                recordID += "NULL"
            } else {
                recordID += value as! String
            }
        }
        return CKRecord.ID(recordName: recordID)
    }
    
}
