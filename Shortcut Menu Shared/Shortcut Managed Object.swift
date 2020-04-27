//
//  Shortcut data model.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 12/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import CoreData

public class ShortcutMO : NSManagedObject {

    @NSManaged public var idString: String
    @NSManaged public var name: String
    @NSManaged public var url: String
    @NSManaged public var urlSecurityBookmark: Data?
    @NSManaged public var copyPrivate: Bool
    @NSManaged public var copyText: String
    @NSManaged public var copyMessage: String
    @NSManaged public var section: String
    @NSManaged public var sequence64: Int64

}

extension ShortcutMO: Identifiable {
    
    public var id: UUID {
        get {
            return UUID(uuidString: idString) ?? UUID()
        }
        set {
            self.idString = newValue.uuidString
        }
    }
    
    public var sequence: Int {
        get {
            return Int(sequence64)
        }
        set {
            self.sequence64 = Int64(newValue)
        }
    }
    
}
