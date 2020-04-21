//
//  Shortcut data model.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 12/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import CoreData

public enum ShortcutType: String, CaseIterable {
    case clipboard = "clipboard"
    case url = "url"
    
    public var description: String {
        switch self {
        case .clipboard:
            return "Copy to clipboard"
        case .url:
            return "Open URL"
        }
    }
}

public class ShortcutMO : NSManagedObject {

    @NSManaged public var idString: String
    @NSManaged public var name: String
    @NSManaged public var value: String
    @NSManaged public var typeString: String
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
    
    public var type: ShortcutType {
        get {
            return ShortcutType(rawValue: self.typeString) ?? ShortcutType.clipboard
        }
        set {
            self.typeString = newValue.rawValue
        }
    }
    
}
