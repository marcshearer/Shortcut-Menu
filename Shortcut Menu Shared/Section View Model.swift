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

public class SectionViewModel : ObservableObject, Identifiable, Hashable {
    
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
    @Published public var shared: Bool

    // Linked managed objects
    private var sectionMO: SectionMO?
    private var cloudSectionMO: CloudSectionMO?
        
    // Other properties
    @Published public var nameError: String = ""
    @Published public var canSave: Bool = false
    @Published public var canEditKeyEquivalent: Bool = false

    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Hasher for lists - only dependent on id and shared
    public var listHasher: Int {
        var hasher = Hasher()
        hasher.combine(self.id)
        hasher.combine(self.shared)
        return hasher.finalize()
    }
    
    init(id: UUID? = nil, isDefault: Bool = false, name: String = "", sequence: Int = 0, menuTitle: String = "", keyEquivalent: String = "", inline: Bool = false, shared: Bool = false) {
        self.id = id ?? (isDefault ? defaultUUID : UUID())
        self.isDefault = isDefault
        self.name = name
        self.sequence = sequence
        self.keyEquivalent = keyEquivalent
        self.inline = inline
        self.shared = shared
        self.menuTitle = menuTitle
        
        self.setupMappings()
    }

    convenience init() {
        self.init(id: UUID(), name: "", sequence: 0)
    }
    
    convenience init(sectionMO: SectionBaseMO, shared: Bool) {
        self.init(id: sectionMO.id, isDefault: sectionMO.isDefault, name: sectionMO.name, sequence: sectionMO.sequence, menuTitle: sectionMO.menuTitle, keyEquivalent: sectionMO.keyEquivalent, inline: sectionMO.inline, shared: sectionMO.shared)
        if shared {
            self.cloudSectionMO = sectionMO as? CloudSectionMO
        } else {
            self.sectionMO = sectionMO as? SectionMO
        }
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
                return (menuTitle == "")
            }
            .sink { (canEditKeyEquivalent) in
                if !canEditKeyEquivalent && (self.keyEquivalent != "" || self.canEditKeyEquivalent) {
                    self.keyEquivalent = ""
                    self.canEditKeyEquivalent = false
                }
            }
            .store(in: &cancellableSet)
        
        $shared
            .receive(on: RunLoop.main)
            .map { (shared) in
                return (shared)
            }
            .sink { (shared) in
                if !shared {
                    // Propagate to children
                    self.cascadeShared(shared: shared)
                }
            }
            .store(in: &cancellableSet)
        
    }
    
    public static func == (lhs: SectionViewModel, rhs: SectionViewModel) -> Bool {
        lhs.id == rhs.id && lhs.isDefault == rhs.isDefault && lhs.name == rhs.name && lhs.sequence == rhs.sequence && lhs.menuTitle == rhs.menuTitle && lhs.keyEquivalent == rhs.keyEquivalent && lhs.inline == rhs.inline && lhs.shared == rhs.shared
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isDefault)
        hasher.combine(name)
        hasher.combine(sequence)
        hasher.combine(menuTitle)
        hasher.combine(keyEquivalent)
        hasher.combine(inline)
        hasher.combine(shared)
        hasher.combine(sectionMO)
        hasher.combine(cloudSectionMO)
    }
    
    private func exists(name: String) -> Bool {
        return MasterData.shared.sections.contains(where: {$0.name == name && $0.id != self.id})
    }
    
    public var shortcuts: [ShortcutViewModel] {
        return MasterData.shared.shortcuts.filter({ $0.section?.id == self.id })
    }
    
    public func copy() -> SectionViewModel {
        let copy = SectionViewModel(id: self.id, isDefault: isDefault, name: self.name, sequence: self.sequence, menuTitle: self.menuTitle, keyEquivalent: self.keyEquivalent, inline: self.inline, shared: shared)
        copy.sectionMO = self.sectionMO
        copy.cloudSectionMO = self.cloudSectionMO
        return copy
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
    
    public var canShare: Bool {
        var canShare = true
        for parentShortcut in MasterData.shared.shortcuts.filter({$0.type == .section && $0.nestedSection?.id == self.id}) {
            // Should only be one parent, but belts and braces
            canShare = canShare && (parentShortcut.section?.isShared ?? false)
        }
        return canShare
    }
    
    public var isShared: Bool {
        return self.canShare && self.shared
    }
    
    public func cascadeShared(shared: Bool) {
        for shortcut in self.shortcuts {
            shortcut.shared = shared
            shortcut.save()
            if shortcut.type == .section {
                if let nested = shortcut.nestedSection {
                    if nested.shared != shared {
                        nested.shared = shared
                        nested.save()
                    }
                }
            }
        }
    }
    
    public func save() {
        // Note the default section is stored in both the local and cloud database if it is shared
        // Other sections are stored in the cloud if shared, local otherwise
        
        if self.isShared {
            if self.sectionMO != nil && !self.isDefault {
                // Need to delete local record (unless this is default section)
                context.delete(self.sectionMO!)
                self.sectionMO = nil
            }
            if self.cloudSectionMO == nil {
                // Need to create cloud record
                self.cloudSectionMO = CloudSectionMO(context: context)
            }
            if !self.shared {
                self.shared = true
            }
            self.toManagedObject(sectionMO: self.cloudSectionMO!)
            
            // Keep local default section in line (in case cloud record is deleted)
            if self.isDefault {
                if self.sectionMO == nil {
                    // Need to create local record
                    self.sectionMO = SectionMO(context: context)
                }
                self.toManagedObject(sectionMO: self.sectionMO!)
                self.sectionMO?.shared = false
            }
        } else {
            if self.cloudSectionMO != nil {
                // Need to delete cloud record
                context.delete(self.cloudSectionMO!)
                self.cloudSectionMO = nil
            }
            if self.sectionMO == nil {
                // Need to create local record
                self.sectionMO = SectionMO(context: context)
            }
            if self.shared {
                self.shared = false
            }
            self.toManagedObject(sectionMO: self.sectionMO!)
        }
        
        do {
            try context.save()
        } catch {
            fatalError("Error writing section")
        }
    }
    
    private func toManagedObject(sectionMO: SectionBaseMO) {
        sectionMO.id = self.id
        sectionMO.isDefault = self.isDefault
        sectionMO.name = self.name
        sectionMO.sequence = self.sequence
        sectionMO.keyEquivalent = self.keyEquivalent
        sectionMO.inline = self.inline
        sectionMO.shared = self.shared
        sectionMO.menuTitle = self.menuTitle
        sectionMO.lastUpdate = Date()
    }
    
    public func remove() {
        if self.sectionMO != nil {
            context.delete(self.sectionMO!)
        }
        self.sectionMO = nil
        
        if self.cloudSectionMO != nil {
            context.delete(self.cloudSectionMO!)
        }
        self.cloudSectionMO = nil
        
        do {
            try context.save()
        } catch {
            fatalError("Error removing section")
        }
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
                if item.hasItemConformingToTypeIdentifier(SectionItemProvider.type.identifier) {
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
