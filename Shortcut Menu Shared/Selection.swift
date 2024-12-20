//
//  Selection.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import Combine
import UniformTypeIdentifiers

public class Selection : ObservableObject, Identifiable {
    
    private var master: MasterData = MasterData.shared
    @Published public var sections: [SectionViewModel]
    @Published public var selectedSection: SectionViewModel?
    @Published public var editSection = SectionViewModel()
    @Published public var shortcuts: [ShortcutViewModel] = []
    @Published public var shortcutsTitle: String = "No Section Selected"
    @Published public var selectedShortcut: ShortcutViewModel?
    @Published public var editShortcut = ShortcutViewModel()
    @Published public var editAction: EditAction = .none
    @Published public var editObject: EditObject = .none
    @Published public var canExit: Bool = false
    @Published public var singleSection: Bool = false
    @Published public var id = UUID()
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []

    init() {
        self.sections = self.master.mainSections
        
        self.setupMappings()
    }
    
    convenience init(section: SectionViewModel?) {
        self.init()
        if let section = section {
            self.selectSection(section: section)
        }
    }
    
    func setupMappings() {
        $editAction
            .receive(on: RunLoop.main)
            .map { (editAction) in
                return (editAction == .none)
            }
        .assign(to: \.canExit, on: self)
        .store(in: &cancellableSet)
    }
    
    func selectSection(section name: String, updateShortcuts: Bool = true) {
        if let section = master.section(named: name) {
            self.selectSection(section: section, updateShortcuts: updateShortcuts)
        }
    }
    
    func selectSection(section: SectionViewModel?, updateShortcuts: Bool = true) {
        
        if self.editObject != .section || self.editSection != section {
            self.editAction = .none
        }
    
        self.selectedShortcut = nil
        self.editShortcut = ShortcutViewModel()
        
        self.selectedSection = master.section(withId: section?.id)
        
        if let selectedSection = self.selectedSection {
            
            self.editSection = selectedSection.copy()
            self.editObject = .section

            if updateShortcuts {
                self.shortcuts = selectedSection.shortcuts
                self.shortcutsTitle = "\(selectedSection.titleName)\(MyApp.format == .phone ? "" : " Shortcuts")"
            }
            
        } else {
            
            self.deselectSection()
            
        }
    }
    
    func deselectSection() {
        
        self.selectedSection = nil
        self.editSection = SectionViewModel()
        self.shortcuts = []
        self.shortcutsTitle = "No Section Selected"
        self.editObject = .none
        self.editAction = .none
        
    }
    
    func updateSection(section: SectionViewModel) {
        
        var oldName: String?
        
        if let updateIndex = self.master.sections.firstIndex(where: {$0.id == section.id}) {
            oldName = self.master.sections[updateIndex].name
            self.master.sections[updateIndex] = section
        } else {
            self.master.sections.append(section)
        }
        section.save()
        
        self.sections = master.mainSections
        
        // Need to update sections on shortcuts in this section
        // Note that we have created a new copy section so they need to be overwritten even if the id matches
        for shortcut in section.shortcuts {
            shortcut.section = section
        }
        
        // Need to update section names and shared flags on shortcuts which nest this section
        for shortcut in self.master.shortcuts.filter({$0.action == .nestedSection && $0.nestedSection?.name == oldName}) {
            shortcut.nestedSection = section
            shortcut.name = section.name
            if true || oldName != section.name || shortcut.shared != section.shared {
                shortcut.shared = section.shared
                self.updateShortcut(shortcut: shortcut)
            }
        }
        self.selectSection(section: section)
    }
    
    func removeSection(section: SectionViewModel) {
        
        for shortcut in self.master.shortcuts.filter({$0.section?.id == section.id}) {
            self.removeShortcut(shortcut: shortcut)
        }
        
        if let removeIndex = self.master.sections.firstIndex(where: {$0.id == section.id}) {
            self.master.sections.remove(at: removeIndex)
            section.remove()
            
            self.sections = master.mainSections
            self.deselectSection()
            
        }
    }
    
    func newSection() {
        self.deselectSection()
        self.editSection = SectionViewModel()
        self.editSection.sequence = master.nextSectionSequence()
        self.editAction = .create
        self.editObject = .section
    }
    
    public func updateSectionSequence() {
        var last = 0
        for section in self.sections {
            if section.sequence != last + 1 {
                section.sequence = last + 1
                if section.id == self.editSection.id && section.sequence != self.editSection.sequence {
                    self.editSection.sequence = section.sequence
                }
                section.save()
            }
            last = section.sequence
        }
    }
        
    func selectShortcut(shortcut name: String) {
        if let shortcut = self.shortcuts.first(where: {$0.name == name}) {
            self.selectShortcut(shortcut: shortcut)
        }
    }
    
    func selectShortcut(shortcut: ShortcutViewModel) {
        
        if self.editObject != .shortcut || self.editShortcut != shortcut {
            self.editAction = .none
        }
        
        self.selectedShortcut = self.shortcuts.first(where: {$0.id == shortcut.id})
        
        if self.selectedShortcut != nil {
            
            self.editShortcut = self.selectedShortcut!.copy()
            self.editObject = .shortcut
            
        } else {
            
            self.deselectShortcut()
            
        }
    }
    
    func deselectShortcut() {
        
        self.selectedShortcut = nil
        self.editShortcut = ShortcutViewModel()
        self.editSection = SectionViewModel()
        self.editObject = .none
        self.editAction = .none

}
    
    func updateShortcut(shortcut: ShortcutViewModel) {
        var new = false
        
        if let updateIndex = self.master.shortcuts.firstIndex(where: {$0.id == shortcut.id}) {
            self.master.shortcuts[updateIndex] = shortcut
        } else {
            if let beforeIndex = self.master.shortcuts.firstIndex(where: {$0.sequence > shortcut.sequence}) {
                //This isn't the highest sequence - try to insert in the right place
                self.master.shortcuts.insert(shortcut, at: beforeIndex)
            } else {
                self.master.shortcuts.append(shortcut)
            }
            new = true
        }
        shortcut.save()
        
        // Update selection
        if let index = self.shortcuts.firstIndex(where: {$0.id == shortcut.id}) {
            self.shortcuts[index] = shortcut
        }
        
        if let section = shortcut.section {
            
            let updateSelected: Bool = (new || self.selectedShortcut?.id == shortcut.id)
            
            self.selectSection(section: section)
            
            if updateSelected {
                self.selectShortcut(shortcut: shortcut)
            }
        }
    }
    
    func removeShortcut(shortcut: ShortcutViewModel) {
        if let removeIndex = self.master.shortcuts.firstIndex(where: {$0.id == shortcut.id}) {
            self.master.shortcuts.remove(at: removeIndex)
            shortcut.remove()
            self.deselectShortcut()
            if self.selectedSection != nil {
                self.selectSection(section: self.selectedSection!)
            }
        }
    }
    
    func newShortcut(section: SectionViewModel, shortcut: ShortcutViewModel? = nil) {
        self.deselectShortcut()
        if let shortcut = shortcut {
            self.editShortcut = shortcut
        } else {
            self.editShortcut = ShortcutViewModel()
            self.editShortcut.sequence = master.nextShortcutSequence(section: section)
        }
        self.editShortcut.section = section
        self.editAction = .create
        self.editObject = .shortcut
    }
    
    func newNestedSectionShortcut(in section: SectionViewModel, to nestedSection: SectionViewModel, at index: Int? = nil) {
        self.deselectShortcut()
        self.selectSection(section: section)
        let shortcut = ShortcutViewModel()
        shortcut.name = nestedSection.name
        shortcut.section = section
        shortcut.action = .nestedSection
        shortcut.nestedSection = nestedSection
        if !section.shared {
            nestedSection.shared = false
            nestedSection.save()
            shortcut.shared = false
        } else {
            shortcut.shared = nestedSection.shared
        }
        self.editAction = .none
        if let index = index {
            self.shortcuts.insert(shortcut, at: index)
        } else {
            self.shortcuts.append(shortcut)
        }
        self.updateShortcutSequence()
        self.updateShortcut(shortcut: shortcut)
    }
    
    func getSection(id: UUID) -> SectionViewModel? {
        return self.sections.first(where: { $0.id == id })
    }
    
    @discardableResult public func updateShortcutSequence(leavingGapAfter: ShortcutViewModel? = nil) -> Int {
        var last = 0
        var gapSequence = 0
        
        for shortcut in self.shortcuts {
            if shortcut.sequence != last + 1 {
                shortcut.sequence = last + 1
                shortcut.save()
                if shortcut.id == self.editShortcut.id && shortcut.sequence != self.editShortcut.sequence {
                    self.editShortcut.sequence = shortcut.sequence
                }
            }
            last = shortcut.sequence
            if shortcut.id == leavingGapAfter?.id {
                gapSequence = last + 1
                last += 1
            }
        }
        return gapSequence
    }
    
    public func dropUrl(afterIndex: Int? = nil, section: SectionViewModel? = nil, items: [NSItemProvider]) {
        DispatchQueue.main.async {
            for item in items {
                item.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil, completionHandler: { (url, error) in
                    if let data = url as? Data {
                        DispatchQueue.main.async {
                            if let urlString = String(data: data, encoding: .utf8) {
                                if let url = URL(string: urlString) {
                                    LinkPresentation.getDetail(url: url) { (result) in
                                        Utility.mainThread {
                                            var name = ""
                                            switch result {
                                            case .success(let (_, urlName)):
                                                name = urlName ?? ""
                                            default:
                                                break
                                            }
                                            
                                            var urlString: String?
                                            var urlSecurityBookmark: Data?
                                            if item.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
#if canImport(AppKit)
                                                if let bookmarkData = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                                                    urlString = url.absoluteString
                                                    urlSecurityBookmark = bookmarkData
                                                }
#endif
                                            } else if item.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                                                urlString = url.absoluteString
                                            }
                                            
                                            if let urlString = urlString {
                                                self.createShortcut(section: section, name: name, url: urlString, urlSecurityBookmark: urlSecurityBookmark, afterIndex: afterIndex)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    public func dropString(afterIndex: Int? = nil, section: SectionViewModel? = nil, items: [NSItemProvider]) {
        DispatchQueue.main.async {
            for item in items {
                item.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil, completionHandler: { (string, error) in
                    if let string = string {
                        if let string = try? NSAttributedString(data: string as! Data, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
                            DispatchQueue.main.async {
                                self.createShortcut(section: section, name: string.string, copyText: string.string, afterIndex: afterIndex)
                            }
                        }
                    }
                })
            }
        }
    }
    
    func createShortcut(section: SectionViewModel?, name: String, url: String = "", urlSecurityBookmark: Data? = nil, copyText: String = "", afterIndex: Int? = 0) {
        // Use provided section or if none use selected section or default
        let section = section ?? self.selectedSection ?? self.master.defaultSection!
        
        // Switch to this section
        self.selectSection(section: section)
        
        //Create shortcut
        let shortcut = ShortcutViewModel()
        shortcut.name = name
        shortcut.url = url
        shortcut.urlSecurityBookmark = urlSecurityBookmark
        shortcut.copyText = copyText
        
        // Work out where to put it - if no index insert at end
        let insertAfterIndex = afterIndex ?? section.shortcuts.count
        let insertAfter = (insertAfterIndex == 0 ? nil : section.shortcuts[insertAfterIndex - 1])
        shortcut.sequence = self.updateShortcutSequence(leavingGapAfter: insertAfter)
        
        // Create the shortcut
        self.newShortcut(section: (section), shortcut: shortcut)
    }
    
    func getSection(name: String) -> SectionViewModel? {
        return self.sections.first(where: { $0.name == name })
    }
    
    func getShortcut(id: UUID) -> ShortcutViewModel? {
        return self.shortcuts.first(where: { $0.id == id })
    }
    
    func getSectionIndex(id: UUID) -> Int? {
        return self.sections.firstIndex(where: { $0.id == id })
    }
    
    func getShortcutIndex(id: UUID) -> Int? {
        return self.shortcuts.firstIndex(where: { $0.id == id })
    }
}

