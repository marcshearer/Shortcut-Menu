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
import UniformTypeIdentifiers

public class SectionViewModel : ObservableObject, Identifiable {

    // Managed object context
    let context: NSManagedObjectContext! = MasterData.context

    // Properties in core data model
    public let id: UUID
    @Published public var isDefault: Bool
    @Published public var name:String
    @Published public var sequence: Int
    @Published public var menuTitle: String
    @Published public var keyEquivalent: String
    @Published public var inline: Bool

    // Linked managed object
    private var sectionMO: SectionMO?
    
    // Link to master data (required for checking duplicates)
    private var master: MasterData?
    
    // Other properties
    @Published public var nameError: String = ""
    @Published public var canSave: Bool = false
    @Published public var canEditKeyEquivalent: Bool = false

    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(id: UUID = UUID(), isDefault: Bool = false, name: String = "", sequence: Int = 0, menuTitle: String = "", keyEquivalent: String = "", inline: Bool = false, sectionMO: SectionMO? = nil, master: MasterData?) {
        self.id = id
        self.isDefault = isDefault
        self.name = name
        self.sequence = sequence
        self.keyEquivalent = keyEquivalent
        self.inline = inline
        self.menuTitle = menuTitle
        self.sectionMO = sectionMO
        self.master = master
        
        self.setupMappings()
    }

    convenience init(master: MasterData? = nil) {
        self.init(id: UUID(), name: "", sequence: 0, master: master)
    }
    
    convenience init(sectionMO: SectionMO, master: MasterData) {
        self.init(id: sectionMO.id, isDefault: sectionMO.isDefault, name: sectionMO.name, sequence: sectionMO.sequence, menuTitle: sectionMO.menuTitle, keyEquivalent: sectionMO.keyEquivalent, inline: sectionMO.inline, sectionMO: sectionMO, master: master)
    }
    
    private func setupMappings() {
        
        Publishers.CombineLatest($name, $isDefault)
            .receive(on: RunLoop.main)
            .map { (name, isDefault) in
                return (name.isEmpty && !isDefault ? "Name must be non-blank" : (self.exists(name: name) ? "Name already exists" : ""))
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
        
        $menuTitle
            .receive(on: RunLoop.main)
            .map { (menuTitle) in
                return (menuTitle == "" ? "" : self.keyEquivalent)
            }
        .assign(to: \.keyEquivalent, on: self)
        .store(in: &cancellableSet)
        
        $menuTitle
            .receive(on: RunLoop.main)
            .map { (menuTitle) in
                return (menuTitle != "")
            }
        .assign(to: \.canEditKeyEquivalent, on: self)
        .store(in: &cancellableSet)
    }
    
    private func exists(name: String) -> Bool {
        return self.master?.sections.contains(where: {$0.name == name && $0.id != self.id}) ?? false
    }
    
    public var shortcuts: [ShortcutViewModel] {
        return self.master?.shortcuts.filter({ $0.section?.id == self.id }) ?? []
    }
    
    public func copy() -> SectionViewModel {
        return SectionViewModel(id: self.id, isDefault: isDefault, name: self.name, sequence: self.sequence, menuTitle: self.menuTitle, keyEquivalent: self.keyEquivalent, sectionMO: self.sectionMO, master: self.master)
    }
    
    public var displayName: String {
        if self.isDefault {
            return defaultSectionDisplayName
        } else {
            return self.name
        }
    }
    
    public var menuName: String {
        if self.isDefault {
            return defaultSectionMenuName
        } else {
            return self.name
        }
    }
    
    public var titleName: String {
        if self.isDefault {
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
        self.sectionMO!.isDefault = self.isDefault
        self.sectionMO!.name = self.name
        self.sectionMO!.sequence = self.sequence
        self.sectionMO!.keyEquivalent = self.keyEquivalent
        self.sectionMO!.inline = self.inline
        self.sectionMO!.menuTitle = self.menuTitle
    }
}

@objc final class SectionItemProvider: NSObject, NSItemProviderReading, NSItemProviderWriting {
    // Note: also had to declare this in info.plist
    public let id: UUID
    
    init(id: UUID) {
        self.id = id
    }
        
    static let type = UTType(exportedAs: "com.sheareronline.shortcuts.section", conformingTo: UTType.data)
    
    public static var writableTypeIdentifiersForItemProvider: [String] {
        [type.identifier]
    }
    
    public static var readableTypeIdentifiersForItemProvider: [String] {
        [type.identifier]
    }
    
    public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        
        let progress = Progress(totalUnitCount: 1)
        
        do {
            let data = try JSONSerialization.data(
                withJSONObject:
                    ["type" : SectionItemProvider.type.identifier,
                     "id" : self.id.uuidString],
                options: .prettyPrinted)
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
        if propertyList["type"] == SectionItemProvider.type.identifier {
            id = UUID(uuidString: propertyList["id"] ?? "") ?? UUID()
        } else {
            id = UUID()
        }
        return SectionItemProvider(id: id)
    }
    
    static public func dropAction(at index: Int, _ items: [NSItemProvider], selection: Selection, action: @escaping (Int, Int)->()) {
        DispatchQueue.main.async {
            for item in items {
                _ = item.loadObject(ofClass: SectionItemProvider.self) { (droppedItem, error) in
                    if error == nil {
                        if let droppedItem = droppedItem as? SectionItemProvider {
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

class SectionListDropDelegate: DropDelegate {
    
    private let parent: SetupSectionListView
    private let toId: UUID
    
    init(_ parent: SetupSectionListView, id toId: UUID) {
        self.parent = parent
        self.toId = toId
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return true
    }
    
    func performDrop(info: DropInfo) -> Bool {
        DispatchQueue.main.async {
            
            if let toIndex = self.parent.selection.getSectionIndex(id: self.toId) {
                let shortcutItems = info.itemProviders(for: [ShortcutItemProvider.type.identifier])
                ShortcutItemProvider.dropAction(at: toIndex, shortcutItems, selection: self.parent.selection, action: self.parent.onDropShortcutAction)
                
                let urlItems = info.itemProviders(for: [UTType.url.identifier, UTType.fileURL.identifier])
                let selection = self.parent.selection
                selection.dropUrl(section: selection.sections[toIndex], items: urlItems)
            }
        }
        return true
    }
}
