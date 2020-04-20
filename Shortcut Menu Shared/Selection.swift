//
//  Selection.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import Combine

public class Selection : ObservableObject {
    
    private var master: MasterData = MasterData()
    @Published public var sections: [SectionViewModel]
    @Published public var selectedSection: SectionViewModel?
    @Published public var editSection = SectionViewModel()
    @Published public var shortcuts: [ShortcutViewModel]?
    @Published public var shortcutsTitle: String = "No Section Selected"
    @Published public var selectedShortcut: ShortcutViewModel?
    @Published public var editShortcut = ShortcutViewModel()
    @Published public var editMode: EditMode = .none
    @Published public var editObject: EditObject = .none
    
    init() {
        self.sections = self.master.sections
    }
    
    func selectSection(section: SectionViewModel) {
        
        self.selectedShortcut = nil
        self.editShortcut = ShortcutViewModel()
        
        self.selectedSection = self.sections.first(where: {$0.id == section.id})
        
        if self.selectedSection != nil {
            
            self.editSection = self.selectedSection!.copy()
            self.shortcuts = self.master.shortcuts.filter { $0.section?.name == self.selectedSection?.name}
            self.shortcutsTitle = "\(self.selectedSection!.displayName) Shortcuts"
            self.editObject = (section.name == "" ? .none : .section)
            
        } else {
            
            self.deselectSection()
            
        }
    }
    
    func deselectSection() {
        
        self.selectedSection = nil
        self.editSection = SectionViewModel()
        self.shortcuts = nil
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
        self.editMode = .create
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
    
    func selectShortcut(shortcut: ShortcutViewModel) {
        
        self.selectedShortcut = self.shortcuts?.first(where: {$0.id == shortcut.id})
        
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
        self.editMode = .create
        self.editObject = .shortcut
       }
    
        func getSection(id: UUID) -> SectionViewModel? {
        return self.sections.first(where: { $0.id == id })
    }
    
    public func updateShortcutSequence() {
        var last = 0
        if let shortcuts = self.shortcuts {
            for shortcut in shortcuts {
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
    }
    
    func getSection(name: String) -> SectionViewModel? {
        return self.sections.first(where: { $0.name == name })
    }
    
    func getShortcut(id: UUID) -> ShortcutViewModel? {
        return self.shortcuts?.first(where: { $0.id == id })
    }
    
    func getSectionIndex(id: UUID) -> Int? {
        return self.sections.firstIndex(where: { $0.id == id })
    }
    
    func getShortcutIndex(id: UUID) -> Int? {
        return self.shortcuts?.firstIndex(where: { $0.id == id })
    }
}

