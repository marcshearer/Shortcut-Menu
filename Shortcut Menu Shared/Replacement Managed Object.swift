
//
//  Replacement Managed Object.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 16/12/2024.
//  Copyright © 2024 Marc Shearer. All rights reserved.
//

import CoreData

public class ReplacementMO : NSManagedObject, Identifiable {

    static public let tableName = "Replacement"
    @NSManaged public var token: String
    @NSManaged public var replacement: String
    @NSManaged public var allowedValues: String
    @NSManaged public var expiry: Float
    @NSManaged public var entered: Date?
}
