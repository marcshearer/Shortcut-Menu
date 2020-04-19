//
//  Shortcut View Model.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 12/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import Combine

public class ShortcutViewModel: ObservableObject, Identifiable {
    
    // Properties in core data model
    public var id: UUID
    @Published public var name:String
    @Published public var value: String
    @Published public var section: String
    @Published public var sequence: Int
    
    // Enabled properties
    @Published public var canEditValue:Bool = false
    @Published public var canEditSection: Bool = false
    
    // Other properties
    @Published public var canSave: Bool = false
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    convenience init() {
        self.init(id: UUID(), name: "", value: "", section: "", sequence: 0)
    }
    
    init(id: UUID, name: String, value: String, section: String, sequence: Int) {
        self.id = id
        self.name = name
        self.value = value
        self.section = section
        self.sequence = sequence
        
        self.setupMappings()
    }
    
    private func setupMappings() {
        Publishers.CombineLatest4($name, $value, $section, $sequence)
            .receive(on: RunLoop.main)
            .map { name, value, section, sequence in
                return !name.isEmpty && !value.isEmpty && !section.isEmpty
            }
        .assign(to: \.canSave, on: self)
        .store(in: &cancellableSet)
    }
    
    public func copy() -> ShortcutViewModel {
        return ShortcutViewModel(id: self.id, name: self.name, value: self.value, section: self.section, sequence: self.sequence)
    }
    
    public var itemProvider: NSItemProvider {
        return NSItemProvider(object: ShortcutItemProvider(id: self.id))
    }
    
    public func toManagedObject(shortcutMO: ShortcutMO) {
        shortcutMO.id = self.id
        shortcutMO.name = self.name
        shortcutMO.value = self.value
        shortcutMO.section = self.section
        shortcutMO.sequence = self.sequence
    }
    
    public func fromManagedObject(shortcutMO: ShortcutMO) {
        self.id = shortcutMO.id
        self.name = shortcutMO.name
        self.value = shortcutMO.value
        self.section = shortcutMO.section
        self.sequence = shortcutMO.sequence
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
