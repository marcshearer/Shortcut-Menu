//
//  Section Data Model.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 12/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import CoreData

public class SectionMO : NSManagedObject {

    @NSManaged public var idString: String
    @NSManaged public var name: String
    @NSManaged public var sequence64: Int64
    @NSManaged public var menuTitle: String

}

extension SectionMO: Identifiable {
    
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
