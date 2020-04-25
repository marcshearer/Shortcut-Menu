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
    @Published public var url: String
    @Published public var copyText: String
    @Published public var copyMessage: String
    @Published public var copyPrivate: Bool
    @Published public var section: SectionViewModel?
    @Published public var sequence: Int
    
    // Linked managed object
    private var shortcutMO: ShortcutMO?
    
    // Link to master data (required for checking duplicates)
    private var master: MasterData?
    
    // Other properties
    @Published public var nameError: String = ""
    @Published public var urlError: String = ""
    @Published public var copyTextError: String = ""
    @Published public var copyMessageError: String = ""
    @Published public var canSave: Bool = false
    @Published public var canEditCopyMessage: Bool = false
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(id: UUID, name: String, url: String, copyText: String = "", copyMessage: String = "", copyPrivate: Bool, section: SectionViewModel?, sequence: Int, shortcutMO: ShortcutMO? = nil, master: MasterData?) {
        self.id = id
        self.name = name
        self.url = url
        self.copyText = copyText
        self.copyMessage = copyMessage
        self.copyPrivate = copyPrivate
        self.section = section
        self.sequence = sequence
        self.shortcutMO = shortcutMO
        self.master = master
        
        self.setupMappings()
    }
    
    convenience init(shortcutMO: ShortcutMO, section: SectionViewModel, master: MasterData) {
        self.init(id: shortcutMO.id, name: shortcutMO.name, url: shortcutMO.url, copyText: shortcutMO.copyText, copyMessage: shortcutMO.copyMessage, copyPrivate: shortcutMO.copyPrivate, section: section, sequence: shortcutMO.sequence, shortcutMO: shortcutMO, master: master)
    }
    
    convenience init(master: MasterData? = nil) {
        self.init(id: UUID(), name: "", url: "", copyText: "", copyMessage: "", copyPrivate: false, section: nil, sequence: 0, master: master)
    }
     
    private func setupMappings() {
        
        // Set copy message to blank if copy text is blank
        $copyText
            .receive(on: RunLoop.main)
            .map { (copyText) in
                return (copyText.isEmpty ? "" : self.copyMessage)
            }
        .assign(to: \.copyMessage, on: self)
        .store(in: &cancellableSet)

        // Prevent copy message edit if copy text is blank
        Publishers.CombineLatest($copyText, $copyMessage)
            .receive(on: RunLoop.main)
            .map { (copyText, copyMessage) in
                return !copyText.isEmpty
            }
        .assign(to: \.canEditCopyMessage, on: self)
        .store(in: &cancellableSet)
        
        // Check name is non-blank
        $name
            .receive(on: RunLoop.main)
            .map { (name) in
                return (name.isEmpty ? "Name must be non-blank" : (self.exists(name: name) ? "Name already exists" : ""))
            }
        .assign(to: \.nameError, on: self)
        .store(in: &cancellableSet)
        
        // Check url or copy text non-blank and url valid
        Publishers.CombineLatest($url, $copyText)
            .receive(on: RunLoop.main)
            .map { (url, copyText) in
                let bothEmpty = (url.isEmpty && copyText.isEmpty)
                return (bothEmpty ? "URL or text to copy must be non-blank" : (!self.validUrl(value: url) ? "Invalid URL" : ""))
            }
        .assign(to: \.urlError, on: self)
        .store(in: &cancellableSet)
        
        // Check url or copy text non-blank
        Publishers.CombineLatest($url, $copyText)
            .receive(on: RunLoop.main)
            .map { (url, copyText) in
                let bothEmpty = (url.isEmpty && copyText.isEmpty)
                return (bothEmpty ? "URL or text to copy must be non-blank" :  "")
            }
        .assign(to: \.copyTextError, on: self)
        .store(in: &cancellableSet)
        
        // Check message non-blank if private
        Publishers.CombineLatest($copyMessage, $copyPrivate)
            .receive(on: RunLoop.main)
            .map { (copyMessage, copyPrivate) in
                return (copyMessage.isEmpty && copyPrivate ? "Message must not be blank if private" :  "")
            }
        .assign(to: \.copyMessageError, on: self)
        .store(in: &cancellableSet)
        
        // Check no errors
        Publishers.CombineLatest4($nameError, $urlError, $copyTextError, $copyMessageError)
            .receive(on: RunLoop.main)
            .map { (nameError, urlError, copyTextError, copyMessageError) in
                return (nameError.isEmpty && urlError.isEmpty && copyTextError.isEmpty && copyMessageError.isEmpty)
            }
        .assign(to: \.canSave, on: self)
        .store(in: &cancellableSet)
    }
    
    private func exists(name: String) -> Bool {
        return self.master?.shortcuts.contains(where: {$0.name == name && $0.id != self.id}) ?? false
    }
    
    private func validUrl(value: String) -> Bool {
        if value == "" {
            return true
        } else {
            return URL(string: value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") != nil
        }
    }
    
    public func copy() -> ShortcutViewModel {
        return ShortcutViewModel(id: self.id, name: self.name, url: self.url, copyText: copyText, copyMessage: copyMessage, copyPrivate: copyPrivate, section: self.section, sequence: self.sequence, shortcutMO: self.shortcutMO, master: self.master)
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
        self.shortcutMO!.url = self.url
        self.shortcutMO!.copyText = self.copyText
        self.shortcutMO!.copyMessage = self.copyMessage
        self.shortcutMO!.copyPrivate = self.copyPrivate
        self.shortcutMO!.section = self.section?.name ?? ""
        self.shortcutMO!.sequence = self.sequence
    }
}

@objc final class ShortcutItemProvider: NSObject, NSItemProviderReading, NSItemProviderWriting {
        
    public let id: UUID
    
    init(id: UUID) {
        self.id = id
    }
        
    static let itemProviderType: String = "com.sheareronline.shortcuts.shortcut"
    static let type: String = "shortcut"
    
    public static var writableTypeIdentifiersForItemProvider: [String] = [kUTTypeData as String, ShortcutItemProvider.itemProviderType]
    
    public static var readableTypeIdentifiersForItemProvider: [String] = [kUTTypeData as String, ShortcutItemProvider.itemProviderType]
    
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
                            if let droppedIndex = selection.shortcuts.firstIndex(where: {$0.id == droppedItem.id}) {
                                action(index, droppedIndex)
                            }
                        }
                    }
                }
            }
        }
    }
}
