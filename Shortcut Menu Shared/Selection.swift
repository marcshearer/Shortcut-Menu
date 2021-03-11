//
//  Selection.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import Combine

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
    @Published internal var canExit: Bool = false
    @Published public var id = UUID()
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []

    init() {
        self.sections = self.master.sections.sorted(by: { $0.sequence < $1.sequence })
        
        self.setupMappings()
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
        if let section = self.sections.first(where: {$0.name == name}) {
            self.selectSection(section: section, updateShortcuts: updateShortcuts)
        }
    }
    
    func selectSection(section: SectionViewModel, updateShortcuts: Bool = true) {
        
        self.selectedShortcut = nil
        self.editShortcut = ShortcutViewModel()
        
        self.selectedSection = self.sections.first(where: {$0.id == section.id})
        
        if self.selectedSection != nil {
            
            self.editSection = self.selectedSection!.copy()
            self.editObject = (section.name == "" ? .none : .section)

            if updateShortcuts {
                self.shortcuts = self.master.shortcuts.filter( { $0.section?.name == self.selectedSection?.name} ).sorted(by: {$0.sequence < $1.sequence })
                self.shortcutsTitle = "\(self.selectedSection!.titleName) Shortcuts"
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

        self.sections = master.sections

        // Need to update section names on shortcuts in this section
        for shortcut in self.master.shortcuts.filter({$0.section?.name == oldName}) {
            shortcut.section = section
            if oldName != section.name {
                self.updateShortcut(shortcut: shortcut)
            }
        }
        
        // Need to update section names on shortcuts which nest this section
        for shortcut in self.master.shortcuts.filter({$0.type == .section && $0.nestedSection?.name == oldName}) {
            shortcut.nestedSection = section
            shortcut.name = section.name
            if oldName != section.name {
                self.updateShortcut(shortcut: shortcut)
            }
        }
        
        self.selectSection(section: section)
    }
    
    func removeSection(section: SectionViewModel) {
        
        for shortcut in self.master.shortcuts.filter({$0.section?.name == section.name}) {
            self.removeShortcut(shortcut: shortcut)
        }
        
        if let removeIndex = self.master.sections.firstIndex(where: {$0.id == section.id}) {
            self.master.sections.remove(at: removeIndex)
            section.remove()
            
            self.sections = master.sections
            self.deselectSection()
            
        }
    }
    
    func newSection() {
        self.deselectSection()
        self.editSection = SectionViewModel(master: self.master)
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

}
    
    func updateShortcut(shortcut: ShortcutViewModel) {
        var new = false
        
        if let updateIndex = self.master.shortcuts.firstIndex(where: {$0.id == shortcut.id}) {
            self.master.shortcuts[updateIndex] = shortcut
        } else {
            self.master.shortcuts.append(shortcut)
            new = true
        }
        shortcut.save()
        
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
            if self.selectedSection != nil {
                self.selectSection(section: self.selectedSection!)
            }
        }
    }
    
    func newShortcut(section: SectionViewModel) {
        self.deselectShortcut()
        self.editShortcut = ShortcutViewModel(master: self.master)
        self.editShortcut.section = section
        self.editShortcut.sequence = master.nextShortcutSequence(section: section)
        self.editAction = .create
        self.editObject = .shortcut
    }
    
    func newNestedSectionShortcut(in section: SectionViewModel, to nestedSection: SectionViewModel, at index: Int) {
        self.deselectShortcut()
        let shortcut = ShortcutViewModel(master: self.master)
        shortcut.name = nestedSection.name
        shortcut.section = section
        shortcut.type = .section
        shortcut.nestedSection = nestedSection
        shortcut.sequence = self.master.nextShortcutSequence(section: section)
        self.editAction = .none
        self.shortcuts.insert(shortcut, at: index)
        self.updateShortcutSequence()
        self.updateShortcut(shortcut: shortcut)
        self.selectSection(section: nestedSection, updateShortcuts: false)
    }
    
    func getSection(id: UUID) -> SectionViewModel? {
        return self.sections.first(where: { $0.id == id })
    }
    
    public func updateShortcutSequence() {
        var last = 0
        for shortcut in self.shortcuts {
            if shortcut.sequence != last + 1 {
                shortcut.sequence = last + 1
                shortcut.save()
                if shortcut.id == self.editShortcut.id && shortcut.sequence != self.editShortcut.sequence {
                    self.editShortcut.sequence = shortcut.sequence
                }
            }
            last = shortcut.sequence
        }
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

