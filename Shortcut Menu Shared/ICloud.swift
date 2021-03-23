//
//  iCloud.swift
//  Cloud Database Maintenance
//
//  Created by Marc Shearer on 22/07/2018.
//  Copyright © 2018 Marc Shearer. All rights reserved.
//

import Foundation
import CloudKit

class ICloud {
    
    public static let shared = ICloud()
    
    public var publicDatabase: CKDatabase {
        CKContainer(identifier: iCloudIdentifier).publicCloudDatabase
    }

    public var privateDatabase: CKDatabase {
        CKContainer(identifier: iCloudIdentifier).privateCloudDatabase
    }

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
        let cloudContainer = CKContainer(identifier: iCloudIdentifier)
        let database = database ?? self.publicDatabase
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
    
    public func getDatabaseIdentifier(completion: @escaping (Bool, String?, String?, String?, String?, String?)->()) {
        var database: String?
        var minVersion: String?
        var minMessage: String?
        var infoMessage: String?
        
        self.download(recordType: "Version",
                          downloadAction: { (record) in
                                database = Utility.objectString(cloudObject: record, forKey: "database")
                                minVersion = Utility.objectString(cloudObject: record, forKey: "minVersion")
                                minMessage = Utility.objectString(cloudObject: record, forKey: "minMessage")
                                infoMessage = Utility.objectString(cloudObject: record, forKey: "infoMessage")
                          },
                          completeAction: {
                                completion(true, nil, database, minVersion, minMessage, infoMessage)
                          },
                          failureAction: { (error) in
                                completion(false, "Error downloading version \(self.errorMessage(error))", nil, nil, nil, nil)
                          })
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
}
