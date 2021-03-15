//
//  Shortcut data model.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 12/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import CoreData

public class ShortcutMO : NSManagedObject {

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var url: String
    @NSManaged public var urlSecurityBookmark: Data?
    @NSManaged public var copyPrivate: Bool
    @NSManaged public var copyText: String
    @NSManaged public var copyMessage: String
    @NSManaged public var sectionId: UUID?
    @NSManaged public var sequence64: Int64
    @NSManaged public var type16: Int16
    @NSManaged public var nestedSectionId: UUID?
    @NSManaged public var keyEquivalent: String
}

extension ShortcutMO: Identifiable {
    
    public var sequence: Int {
        get {
            return Int(sequence64)
        }
        set {
            self.sequence64 = Int64(newValue)
        }
    }
    
    public var type: ShortcutType {
        get { ShortcutType(rawValue: Int(self.type16)) ?? .shortcut }
        set { self.type16 = Int16(newValue.rawValue) }
    }
}
