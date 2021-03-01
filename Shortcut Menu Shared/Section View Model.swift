//
//  Section View Model.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 12/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import CoreData

public class SectionViewModel : ObservableObject, Identifiable {

    // Managed object context
    let context: NSManagedObjectContext! = MasterData.context

    // Properties in core data model
    public let id: UUID
    @Published public var name:String
    @Published public var sequence: Int
    
    // Linked managed object
    private var sectionMO: SectionMO?
    
    // Link to master data (required for checking duplicates)
    private var master: MasterData?
    
    // Other properties
    @Published public var nameError: String = ""
    @Published public var canSave: Bool = false

    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(id: UUID = UUID(), name: String = "", sequence: Int = 0, sectionMO: SectionMO? = nil, master: MasterData?) {
        self.id = id
        self.name = name
        self.sequence = sequence
        self.sectionMO = sectionMO
        self.master = master
        
        self.setupMappings()
    }

    convenience init(master: MasterData? = nil) {
        self.init(id: UUID(), name: "", sequence: 0, master: master)
    }
    
    convenience init(sectionMO: SectionMO, master: MasterData) {
        self.init(id: sectionMO.id, name: sectionMO.name, sequence: sectionMO.sequence, sectionMO: sectionMO, master: master)
    }
    
    private func setupMappings() {
        
        $name
            .receive(on: RunLoop.main)
            .map { name in
                return (name.isEmpty ? "Name must be non-blank" : (self.exists(name: name) ? "Name already exists" : ""))
            }
        .assign(to: \.nameError, on: self)
        .store(in: &cancellableSet)
        
        $nameError
            .receive(on: RunLoop.main)
            .map { (nameError) in
                return nameError == ""
            }
        .assign(to: \.canSave, on: self)
        .store(in: &cancellableSet)

    }
    
    private func exists(name: String) -> Bool {
        return self.master?.sections.contains(where: {$0.name == name && $0.id != self.id}) ?? false
    }
    
    public var shortcuts: Int {
        return self.master?.shortcuts.filter({ $0.section?.id == self.id } ).count ?? 0
    }
    
    public func copy() -> SectionViewModel {
        return SectionViewModel(id: self.id, name: self.name, sequence: self.sequence, sectionMO: self.sectionMO, master: self.master)
    }
    
    public var displayName: String {
        if self.name == "" {
            return defaultSectionDisplayName
        } else {
            return self.name
        }
    }
    
    public var menuName: String {
        if self.name == "" {
            return defaultSectionMenuName
        } else {
            return self.name
        }
    }
    
    public var titleName: String {
        if self.name == "" {
            return defaultSectionTitleName
        } else {
            return self.name
        }
    }
    
    public var itemProvider: NSItemProvider {
        return NSItemProvider(object: SectionItemProvider(id: self.id))
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
        context.delete(self.sectionMO!)
        self.save()
        self.sectionMO = nil
    }
    
    private func toManagedObject() {
        if self.sectionMO == nil {
            // No managed object - create one
            self.sectionMO = SectionMO(context: context)
        }
        self.sectionMO!.id = self.id
        self.sectionMO!.name = self.name
        self.sectionMO!.sequence = self.sequence
    }
}

@objc final class SectionItemProvider: NSObject, NSItemProviderReading, NSItemProviderWriting {
        
    public let id: UUID
    
    init(id: UUID) {
        self.id = id
    }
        
    static let itemProviderType: String = "com.sheareronline.shortcuts.section"
    static let type: String = "section"
    
    public static var writableTypeIdentifiersForItemProvider: [String] {
        return [SectionItemProvider.itemProviderType]
    }
    
    public static var readableTypeIdentifiersForItemProvider: [String] {
        return [SectionItemProvider.itemProviderType]
    }
    
    public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        
        let progress = Progress(totalUnitCount: 1)
        
        do {
            let data = try JSONSerialization.data(withJSONObject:
                        ["type" : ShortcutItemProvider.type,
                         "id" : self.id.uuidString], options: .prettyPrinted)
            progress.completedUnitCount = 1
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        
        return progress
    }
    
    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws ->SectionItemProvider {
        var id: UUID
        let propertyList: [String : String] = try JSONSerialization.jsonObject(with: data, options: []) as! [String : String]
        if propertyList["type"] == ShortcutItemProvider.type {
            id = UUID(uuidString: propertyList["id"] ?? "") ?? UUID()
        } else {
            id = UUID()
        }
        return SectionItemProvider(id: id)
    }
    
    static public func dropAction(at index: Int, _ items: [NSItemProvider], selection: Selection, action: @escaping (Int, Int)->()) {
        DispatchQueue.main.async {
            for item in items {
                _ = item.loadObject(ofClass:SectionItemProvider.self) { (droppedItem, error) in
                    if error == nil {
                        if let droppedItem = droppedItem as?SectionItemProvider {
                            if let droppedIndex = selection.sections.firstIndex(where: {$0.id == droppedItem.id}) {
                                action(index, droppedIndex)
                            }
                        }
                    }
                }
            }
        }
    }
}


