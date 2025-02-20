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
import UniformTypeIdentifiers

public enum ShortcutAction: Int, PickerEnum, Hashable, Identifiable {
    public var id: Self {
        self
    }
    
    case urlLink = 0
    case clipboardText = 1
    case setReplacement = 2
    case nestedSection = 3
    case replacementValue = 4
    
    public var string: String {
        switch self {
        case .urlLink:
            "URL link"
        case .clipboardText:
            "Clipboard text"
        case .setReplacement:
            "Set replacement"
        case.nestedSection:
            "Nested section"
        case .replacementValue:
            "Replacement value"
        }
    }
    
    public static var pickerCases: [ShortcutAction] {
        var result = [ShortcutAction.urlLink, .clipboardText]
        if MasterData.shared.replacements.count(where: {$0.allowedValues == ""}) != 0 {
            result = result + [.setReplacement]
        }
        return result
    }
}

public class ShortcutViewModel: ObservableObject, Identifiable, Hashable {
    
    // Managed object context
    let context: NSManagedObjectContext! = MasterData.context

    // Properties in core data model
    public var id: UUID
    @Published public var name:String
    @Published public var url: String
    @Published public var urlSecurityBookmark: Data?
    @Published public var copyText: String
    @Published public var copyMessage: String
    @Published public var copyPrivate: Bool
    @Published public var section: SectionViewModel?
    @Published public var nestedSection: SectionViewModel?
    @Published public var sequence: Int
    @Published public var keyEquivalent: String
    @Published public var shared: Bool
    @Published public var action: ShortcutAction
    @Published public var replacementToken: String

    // Linked managed object
    private var shortcutMO: ShortcutMO?
    private var cloudShortcutMO: CloudShortcutMO?

    // Other properties
    @Published public var nameError: String = ""
    @Published public var urlError: String = ""
    @Published public var copyTextError: String = ""
    @Published public var copyMessageError: String = ""
    @Published public var copyError: Bool = false
    @Published public var replacementTokenError: String = ""
    @Published public var canSave: Bool = false
    @Published public var canEditCopyMessage: Bool = false
    @Published public var canEditUrl: Bool = true
    @Published public var canShare: Bool = true
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Hasher for lists - only dependent on id and shared
    public var listHasher: Int {
        var hasher = Hasher()
        hasher.combine(self.id)
        hasher.combine(self.shared)
        return hasher.finalize()
    }
    
    init(id: UUID, name: String, action: ShortcutAction = .urlLink, url: String, urlSecurityBookmark: Data? = nil, copyText: String = "", copyMessage: String = "", copyPrivate: Bool = false, section: SectionViewModel? = nil, nestedSection: SectionViewModel? = nil, keyEquivalent: String = "", replacementToken: String = "", shared: Bool = false, sequence: Int = 0) {
        self.id = id
        self.name = name
        self.url = url
        self.urlSecurityBookmark = urlSecurityBookmark
        self.copyText = copyText
        self.copyMessage = copyMessage
        self.copyPrivate = copyPrivate
        self.section = section
        self.nestedSection = nestedSection
        self.keyEquivalent = keyEquivalent
        self.shared = shared
        self.sequence = sequence
        self.action = action
        self.replacementToken = replacementToken
         
        self.setupMappings()
    }
    
    convenience init(shortcutMO: ShortcutBaseMO, section: SectionViewModel, nestedSection: SectionViewModel? = nil, shared: Bool) {
        self.init(id: shortcutMO.id, name: shortcutMO.name, action: shortcutMO.action, url: shortcutMO.url, urlSecurityBookmark: shortcutMO.urlSecurityBookmark, copyText: shortcutMO.copyText, copyMessage: shortcutMO.copyMessage, copyPrivate: shortcutMO.copyPrivate, section: section, nestedSection: nestedSection, keyEquivalent: shortcutMO.keyEquivalent, replacementToken: shortcutMO.replacementToken, shared: shortcutMO.shared, sequence: shortcutMO.sequence)
        if shared {
            self.cloudShortcutMO = shortcutMO as? CloudShortcutMO
        } else {
            self.shortcutMO = shortcutMO as? ShortcutMO
        }
    }
    
    convenience init() {
        self.init(id: UUID(), name: "", url: "")
    }
     
    private func setupMappings() {
        
        // Stop sharing if section becomes an unshared section
        $section
            .receive(on: RunLoop.main)
            .map { (section) in
                return section
            }
            .sink(receiveValue: { (section) in
                if !(section?.shared ?? true) {
                    self.shared = false
                }
            })
        .store(in: &cancellableSet)
        
        // Clear relevant bits on change of action
        $action
            .receive(on: RunLoop.main)
            .sink(receiveValue: { (action) in
                switch action {
                case .urlLink:
                    self.replacementToken = ""
                    self.nestedSection = nil
                case .clipboardText:
                    self.url = ""
                    self.urlSecurityBookmark = nil
                    self.replacementToken = ""
                    self.nestedSection = nil
                case .setReplacement:
                    self.url = ""
                    self.urlSecurityBookmark = nil
                    self.copyText = ""
                    self.copyMessage = ""
                    self.copyPrivate = false
                    self.nestedSection = nil
                case .nestedSection:
                    self.url = ""
                    self.urlSecurityBookmark = nil
                    self.replacementToken = ""
                    self.copyText = ""
                    self.copyMessage = ""
                    self.copyPrivate = false
                    self.keyEquivalent = ""
                default:
                    break
                }
            })
        .store(in: &cancellableSet)
        
        // Prevent edit of URL if bookmark data is present
        $urlSecurityBookmark
            .receive(on: RunLoop.main)
            .map { (urlSecurityBookmark) in
                return (urlSecurityBookmark == nil)
            }
        .assign(to: \.canEditUrl, on: self)
        .store(in: &cancellableSet)
        
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
        
        // Check url non-blank and url valid
        Publishers.CombineLatest3($url, $urlSecurityBookmark, $action)
            .receive(on: RunLoop.main)
            .map { (url, urlSecurityBookmark, action) in
                let result =
                (action != .urlLink ? "" : (((url.trim().left(5) == "file:" && urlSecurityBookmark == nil) ? "Local files must be entered using the folder button":
                    (!self.validUrl(value: url) ? "Invalid URL" : (url == "" ? "URL must be non-blank" : "")))))
                return result
            }
        .assign(to: \.urlError, on: self)
        .store(in: &cancellableSet)
        
        // Check copy text non-blank
        Publishers.CombineLatest($copyText, $action)
            .receive(on: RunLoop.main)
            .map { (copyText, action) in
                return (action != .clipboardText ? "" : ( copyText == "" ? "Clipboard text must be non-blank" :  ""))
            }
        .assign(to: \.copyTextError, on: self)
        .store(in: &cancellableSet)
        
        // Check replacement token valid
        Publishers.CombineLatest($replacementToken, $action)
            .receive(on: RunLoop.main)
            .map { (replacementToken, action) in
                return (action != .setReplacement ? "" : (replacementToken == "" ? "Replacement token must be non-blank" : (!ReplacementViewModel.validToken(replacementToken) ? "Invalid replacement token" : "")))
            }
            .assign(to: \.replacementTokenError, on: self)
        .store(in: &cancellableSet)
        
        // Check message non-blank if private
        Publishers.CombineLatest($copyMessage, $copyPrivate)
            .receive(on: RunLoop.main)
            .map { (copyMessage, copyPrivate) in
                return (copyMessage.isEmpty && copyPrivate ? "Message must not be blank if private" :  "")
            }
        .assign(to: \.copyMessageError, on: self)
        .store(in: &cancellableSet)
        
        // Check message non-blank if private
        Publishers.CombineLatest($copyTextError, $copyMessageError)
            .receive(on: RunLoop.main)
            .map { (copyTextError, copyMessageError) in
                return (!copyTextError.isEmpty || !copyMessageError.isEmpty)
            }
            .assign(to: \.copyError, on: self)
            .store(in: &cancellableSet)
        
        // Check no errors
        Publishers.CombineLatest4($nameError, $urlError, $replacementTokenError, $copyError)
            .receive(on: RunLoop.main)
            .map { (nameError, urlError, replacementTokenError, copyError) in
                return (nameError.isEmpty && urlError.isEmpty && replacementTokenError.isEmpty && !copyError)
            }
        .assign(to: \.canSave, on: self)
        .store(in: &cancellableSet)
        
        // Make unshared if the copy private flag is set or it has bookmark data
        Publishers.CombineLatest($copyPrivate, $urlSecurityBookmark)
            .map { (copyPrivate, urlSecurityBookmark) in
                return (!copyPrivate && urlSecurityBookmark == nil)
            }
            .sink(receiveValue: { canShare in
                if !canShare && self.shared  {
                    self.shared = false
                }
                self.canShare = canShare
            })
        .store(in: &cancellableSet)
    }
    
    public static func == (lhs: ShortcutViewModel, rhs: ShortcutViewModel) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.url == rhs.url && lhs.urlSecurityBookmark == rhs.urlSecurityBookmark && lhs.copyText == rhs.copyText && lhs.copyMessage == rhs.copyMessage && lhs.copyPrivate == rhs.copyPrivate && lhs.section?.id == rhs.section?.id && lhs.nestedSection?.id == rhs.nestedSection?.id && lhs.sequence == rhs.sequence && lhs.keyEquivalent == rhs.keyEquivalent && lhs.shared == rhs.shared && lhs.action != rhs.action && lhs.replacementToken != rhs.replacementToken
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(url)
        hasher.combine(urlSecurityBookmark)
        hasher.combine(copyText)
        hasher.combine(copyMessage)
        hasher.combine(copyPrivate)
        hasher.combine(section?.id)
        hasher.combine(nestedSection?.id)
        hasher.combine(sequence)
        hasher.combine(keyEquivalent)
        hasher.combine(shared)
        hasher.combine(replacementToken)
        hasher.combine(action)
    }
    
    private func exists(name: String) -> Bool {
        return MasterData.shared.shortcuts.contains(where: {$0.name == name && $0.id != self.id})
    }
    
    private func validUrl(value: String) -> Bool {
        if value == "" {
            return true
        } else {
            return URL(string: value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") != nil
        }
    }
    
    public func copy() -> ShortcutViewModel {
        let copy = ShortcutViewModel(id: self.id, name: self.name, action: self.action, url: self.url, urlSecurityBookmark: self.urlSecurityBookmark, copyText: copyText, copyMessage: copyMessage, copyPrivate: copyPrivate, section: self.section, nestedSection: self.nestedSection, keyEquivalent: self.keyEquivalent, replacementToken: replacementToken, shared: self.shared, sequence: self.sequence)
        copy.shortcutMO = self.shortcutMO
        copy.cloudShortcutMO = self.cloudShortcutMO
        return copy
    }
    
    public var itemProvider: NSItemProvider {
        if action == .nestedSection {
            return NSItemProvider(object: NestedSectionItemProvider(id: self.id))
        } else {
            return NSItemProvider(object: ShortcutItemProvider(id: self.id))
        }
    }
    
    public var isShared: Bool {
        let shared = (self.action == .nestedSection ? (self.nestedSection?.shared ?? false) : self.shared)
        return shared && (self.section?.isShared ?? false) && !self.copyPrivate && self.urlSecurityBookmark == nil
    }
    
    public func save() {
        if self.isShared {
            if self.shortcutMO != nil {
                // Need to delete local record
                context.delete(self.shortcutMO!)
                self.shortcutMO = nil
            }
            if self.cloudShortcutMO == nil {
                // Need to create cloud record
                self.cloudShortcutMO = CloudShortcutMO(context: context)
            }
            self.shared = true
            self.toManagedObject(shortcutMO: self.cloudShortcutMO!)
        } else {
            if self.cloudShortcutMO != nil {
                // Need to delete cloud record
                context.delete(self.cloudShortcutMO!)
                self.cloudShortcutMO = nil
            }
            if self.shortcutMO == nil {
                // Need to create local record
                self.shortcutMO = ShortcutMO(context: context)
            }
            self.shared = false
            self.toManagedObject(shortcutMO: self.shortcutMO!)
        }
        do {
            try context.save()
        } catch {
            fatalError("Error writing shortcut")
        }
    }
    
    public func toManagedObject(shortcutMO: ShortcutBaseMO) {
        shortcutMO.id = self.id
        shortcutMO.name = self.name
        shortcutMO.action = self.action
        shortcutMO.url = self.url
        shortcutMO.urlSecurityBookmark = self.urlSecurityBookmark
        shortcutMO.copyText = self.copyText
        shortcutMO.copyMessage = self.copyMessage
        shortcutMO.copyPrivate = self.copyPrivate
        shortcutMO.sectionId = self.section?.id
        shortcutMO.nestedSectionId = self.nestedSection?.id
        shortcutMO.keyEquivalent = self.keyEquivalent
        shortcutMO.replacementToken = self.replacementToken
        shortcutMO.shared = shared
        shortcutMO.sequence = self.sequence
        shortcutMO.lastUpdate = Date()
    }
    
    public func remove() {
        if self.shortcutMO != nil {
            context.delete(self.shortcutMO!)
        }
        self.shortcutMO = nil
        
        if self.cloudShortcutMO != nil {
            context.delete(self.cloudShortcutMO!)
        }
        self.cloudShortcutMO = nil
        
        do {
            try context.save()
        } catch {
            fatalError("Error removing shortcut")
        }
    }
}

@objc class ShortcutItemProviderBase: NSObject {
    
    public let id: UUID
    private var type: UTType
    
    init(id: UUID, type: UTType) {
        self.id = id
        self.type = type
    }
    
    @objc public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        
        let progress = Progress(totalUnitCount: 1)
        
        do {
            let data = try JSONSerialization.data(withJSONObject: ["type" : type.identifier,
                                                                   "id" : self.id.uuidString], options: .prettyPrinted)
            progress.completedUnitCount = 1
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        
        return progress
    }
    
    @objc public static func object(withItemProviderData data: Data, type: UTType) throws -> UUID {
        var id: UUID?
        let propertyList: [String : String] = try JSONSerialization.jsonObject(with: data, options: []) as! [String : String]
        if propertyList["type"] == type.identifier {
            if let idString =  propertyList["id"] {
                if let uuid = UUID(uuidString: idString) {
                    id = uuid
                }
            }
        }
        if id == nil {
            throw ShortcutMenuError.invalidData
        }
        return id!
    }
    
    static public func dropAction(at index: Int, _ items: [NSItemProvider], selection: Selection, action: @escaping (Int, ShortcutViewModel)->()) {
        DispatchQueue.main.async {
            for item in items {
                var classType: NSItemProviderReading.Type?
                if item.hasItemConformingToTypeIdentifier(ShortcutItemProvider.type.identifier) {
                    classType = ShortcutItemProvider.self
                } else if item.hasItemConformingToTypeIdentifier(NestedSectionItemProvider.type.identifier) {
                    classType = NestedSectionItemProvider.self
                }
                if let classType = classType {
                    _ = item.loadObject(ofClass: classType) { (droppedItem, error) in
                        if error == nil {
                            if let droppedItem = droppedItem as? ShortcutItemProviderBase {
                                if let droppedShortcut = MasterData.shared.shortcut(withId: droppedItem.id) {
                                    action(index, droppedShortcut)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@objc final class ShortcutItemProvider: ShortcutItemProviderBase, NSItemProviderReading, NSItemProviderWriting {
    // Note: also had to declare this in info.plist
    
    init(id: UUID) {
        super.init(id: id, type: ShortcutItemProvider.type)
    }
    static let type = UTType(exportedAs: "com.sheareronline.shortcuts.shortcut", conformingTo: UTType.data)

    public static var writableTypeIdentifiersForItemProvider: [String] {
        [type.identifier]
    }

    public static var readableTypeIdentifiersForItemProvider: [String] {
        [type.identifier]
    }
    
    @objc public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> ShortcutItemProvider {
        let id = try ShortcutItemProviderBase.object(withItemProviderData: data, type: ShortcutItemProvider.type)
        return ShortcutItemProvider(id: id)
    }
}

@objc final class NestedSectionItemProvider: ShortcutItemProviderBase, NSItemProviderReading, NSItemProviderWriting {
    // Note: also had to declare this in info.plist
    
    init(id: UUID) {
        super.init(id: id, type: NestedSectionItemProvider.type)
    }
    static let type = UTType(exportedAs: "com.sheareronline.shortcuts.nestedsection", conformingTo: UTType.data)

    public static var writableTypeIdentifiersForItemProvider: [String] {
        [type.identifier]
    }

    public static var readableTypeIdentifiersForItemProvider: [String] {
        [type.identifier]
    }
    
    @objc public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> NestedSectionItemProvider {
        let id = try ShortcutItemProviderBase.object(withItemProviderData: data, type: NestedSectionItemProvider.type)
        return NestedSectionItemProvider(id: id)
    }
}

class ShortcutListDropDelegate: DropDelegate {
    
    private let parent: SetupShortcutListView
    private let toId: UUID
    private var isEntered = false
    
    init(_ parent: SetupShortcutListView, id toId: UUID) {
        self.parent = parent
        self.toId = toId
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        // Only allow drop on nested sections
        var ok = false
        if let shortcut = MasterData.shared.shortcut(withId: self.toId) {
            if shortcut.action == .nestedSection {
                let items = info.itemProviders(for: [ShortcutItemProvider.type.identifier, UTType.url.identifier, UTType.fileURL.identifier])
                if !items.isEmpty {
                    ok = true
                }
            }
        }
        return ok
    }
    
    func performDrop(info: DropInfo) -> Bool {
        // No actual drops allowed for now
        return false
    }
    
    func dropEntered(info: DropInfo) {
        DispatchQueue.main.async {
            if let shortcut = MasterData.shared.shortcut(withId: self.toId) {
                let items = info.itemProviders(for: [ShortcutItemProvider.type.identifier, UTType.url.identifier, UTType.fileURL.identifier])
                if !items.isEmpty {
                    let selection = self.parent.selection
                    self.isEntered = true
                    Utility.executeAfter(delay: 0.5) {
                        if self.isEntered {
                            selection.selectSection(section: shortcut.nestedSection)
                        }
                    }
                }
            }
        }
    }
    
    func dropExited(info: DropInfo) {
        DispatchQueue.main.async {
            self.isEntered = false
        }
    }
}
