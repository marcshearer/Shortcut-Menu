//
//  Shortcut View Model.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 12/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import CoreData

public class ShortcutViewModel: ObservableObject, Identifiable {

    // Managed object context
    let context: NSManagedObjectContext! = MasterData.context

    // Properties in core data model
    public var id: UUID
    @Published public var name:String
    @Published public var value: String
    @Published public var section: SectionViewModel?
    @Published public var sequence: Int
    
    // Linked managed object
    private var shortcutMO: ShortcutMO?
    
    // Link to master data (required for checking duplicates)
    private var master: MasterData?
    
    // Other properties
    @Published public var nameError: String = ""
    @Published public var valueError: String = ""
    @Published public var canSave: Bool = false
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(id: UUID, name: String, value: String, section: SectionViewModel?, sequence: Int, shortcutMO: ShortcutMO? = nil, master: MasterData?) {
        self.id = id
        self.name = name
        self.value = value
        self.section = section
        self.sequence = sequence
        self.shortcutMO = shortcutMO
        self.master = master
        
        self.setupMappings()
    }
    
    convenience init(shortcutMO: ShortcutMO, section: SectionViewModel, master: MasterData) {
        self.init(id: shortcutMO.id, name: shortcutMO.name, value: shortcutMO.value, section: section, sequence: shortcutMO.sequence, shortcutMO: shortcutMO, master: master)
    }
    
    convenience init(master: MasterData? = nil) {
        self.init(id: UUID(), name: "", value: "", section: nil, sequence: 0, master: master)
    }
     
    private func setupMappings() {
        
        $name
            .receive(on: RunLoop.main)
            .map { name in
                return (name.isEmpty ? "Name must be non-blank" : (self.exists(name: name) ? "Name already exists" : ""))
            }
        .assign(to: \.nameError, on: self)
        .store(in: &cancellableSet)
        
        $value
            .receive(on: RunLoop.main)
            .map { value in
                return (value.isEmpty ? "Value must be non-blank" : "")
            }
        .assign(to: \.valueError, on: self)
        .store(in: &cancellableSet)
        
        Publishers.CombineLatest($nameError, $valueError)
            .receive(on: RunLoop.main)
            .map { (nameError, valueError) in
                return (nameError == "" && valueError == "")
            }
        .assign(to: \.canSave, on: self)
        .store(in: &cancellableSet)
    }
    
    private func exists(name: String) -> Bool {        return self.master?.shortcuts.contains(where: {$0.name == name && $0.id != self.id}) ?? false
    }
    
    public func copy() -> ShortcutViewModel {
        return ShortcutViewModel(id: self.id, name: self.name, value: self.value, section: self.section, sequence: self.sequence, shortcutMO: self.shortcutMO, master: self.master)
    }
    
    public var itemProvider: NSItemProvider {
        return NSItemProvider(object: ShortcutItemProvider(id: self.id))
    }
    
    public func save() {
        self.toManagedObject()
        do {
            try context.save()
        } catch {
            fatalError("Error writing section")
        }
    }
    
    public func remove() {
        self.toManagedObject()
        context.delete(self.shortcutMO!)
        self.save()
        self.shortcutMO = nil
    }
    
    public func toManagedObject() {
        if self.shortcutMO == nil {
            // No managed object - create one
            self.shortcutMO = ShortcutMO(context: context)
        }
        self.shortcutMO!.id = self.id
        self.shortcutMO!.name = self.name
        self.shortcutMO!.value = self.value
        self.shortcutMO!.section = self.section?.name ?? ""
        self.shortcutMO!.sequence = self.sequence
    }
}

@objc final class ShortcutItemProvider: NSObject, NSItemProviderReading, NSItemProviderWriting {
        
    public let id: UUID
    
    init(id: UUID) {
        self.id = id
    }
        
    static let itemProviderType: String = "com.shortcut" //kUTTypeData as String
    static let type = "shortcut"
    
    public static var writableTypeIdentifiersForItemProvider: [String] = [ShortcutItemProvider.itemProviderType, kUTTypeData as String]
    
    public static var readableTypeIdentifiersForItemProvider: [String] = [ShortcutItemProvider.itemProviderType, kUTTypeData as String]
    
    public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        
        let progress = Progress(totalUnitCount: 1)
        
        do {
            let data = try JSONSerialization.data(withJSONObject: ["type" : ShortcutItemProvider.type,
                                                                   "id" : self.id.uuidString], options: .prettyPrinted)
            progress.completedUnitCount = 1
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        
        return progress
    }
    
    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> ShortcutItemProvider {
        var id: UUID
        let propertyList: [String : String] = try JSONSerialization.jsonObject(with: data, options: []) as! [String : String]
        if propertyList["type"] == ShortcutItemProvider.type {
            id = UUID(uuidString: propertyList["id"] ?? "") ?? UUID()
        } else {
            id = UUID()
        }
        return ShortcutItemProvider(id: id)
    }
    
    static public func dropAction(at index: Int, _ items: [NSItemProvider], selection: Selection, action: @escaping (Int, Int)->()) {
        DispatchQueue.main.async {
            for item in items {
                _ = item.loadObject(ofClass: ShortcutItemProvider.self) { (droppedItem, error) in
                    if error == nil {
                        if let droppedItem = droppedItem as? ShortcutItemProvider {
                            if let droppedIndex = selection.shortcuts?.firstIndex(where: {$0.id == droppedItem.id}) {
                                action(index, droppedIndex)
                            }
                        }
                    }
                }
            }
        }
    }
}
