//
//  Section Data Model.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 12/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import CoreData

public class SectionMO : SectionBaseMO, ManagedObject {
    
    static public let tableName = "Section"
    
}

public class CloudSectionMO : SectionBaseMO, ManagedObject {

    static public let tableName = "CloudSection"
    
}

public class SectionBaseMO : NSManagedObject, Identifiable {

    @NSManaged public var id: UUID
    @NSManaged public var isDefault: Bool
    @NSManaged public var name: String
    @NSManaged public var sequence64: Int64
    @NSManaged public var menuTitle: String
    @NSManaged public var keyEquivalent: String
    @NSManaged public var inline: Bool
    @NSManaged public var shared: Bool
    @NSManaged public var lastUpdate : Date
    @NSManaged public var temporary: Bool
    @NSManaged public var quickDrop: Bool
    
    public var sequence: Int {
        get {
            return Int(sequence64)
        }
        set {
            self.sequence64 = Int64(newValue)
        }
    }
}
