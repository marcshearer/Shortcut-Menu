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
    
    @Published private var master: Master
    @Published public var sections: [SectionViewModel]
    @Published public var selectedSection: SectionViewModel?
    @Published public var editSection = SectionViewModel()
    @Published public var shortcuts: [ShortcutViewModel]?
    @Published public var shortcutsTitle: String = "No Section Selected"
    @Published public var selectedShortcut: ShortcutViewModel?
    @Published public var editShortcut = ShortcutViewModel()
    @Published public var editMode: EditMode = .none
    @Published public var editObject: EditObject = .none
    
    init(master: Master) {
        self.master = master
        self.sections = master.sections
    }
    
    func selectSection(section: SectionViewModel) {
        
        self.selectedShortcut = nil
        self.editShortcut = ShortcutViewModel()
        
        self.selectedSection = self.sections.first(where: {$0.id == section.id})
        
        if self.selectedSection != nil {
            
            self.editSection = self.selectedSection!.copy()
            self.shortcuts = self.master.shortcuts.filter { $0.section == self.selectedSection?.name}
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
        
        if let updateIndex = self.master.sections.firstIndex(where: {$0.id == section.id}) {
            self.master.sections[updateIndex] = section
        } else {
            self.master.sections.append(section)
        }
        self.sections = master.sections
        self.selectSection(section: section)
        
    }
    
    func removeSection(section: SectionViewModel) {
        
        if let removeIndex = self.master.sections.firstIndex(where: {$0.id == section.id}) {
            self.master.sections.remove(at: removeIndex)
            self.sections = master.sections
            self.deselectSection()
            
        }
    }
    
    func newSection() {
        self.deselectSection()
        self.editSection = SectionViewModel()
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
        
        if let updateIndex = self.master.shortcuts.firstIndex(where: {$0.id == shortcut.id}) {
            self.master.shortcuts[updateIndex] = shortcut
        } else {
            self.master.shortcuts.append(shortcut)
        }
        
        if let section = self.getSection(name: shortcut.section) {
            
            let updateSelected: Bool = (self.selectedShortcut?.id == shortcut.id)
            
            self.selectSection(section: section)
            
            if updateSelected {
                self.selectShortcut(shortcut: shortcut)
            }
        }
    }
    
    func removeShortcut(shortcut: ShortcutViewModel) {
        if let removeIndex = self.master.shortcuts.firstIndex(where: {$0.id == shortcut.id}) {
            self.master.shortcuts.remove(at: removeIndex)
            if self.selectedSection != nil {
                self.selectSection(section: self.selectedSection!)
            }
        }
    }
    
    func newShortcut(section: SectionViewModel? = nil) {
        self.deselectShortcut()
        self.editShortcut = ShortcutViewModel()
        if let section = section {
            self.editShortcut.section = section.name
            self.editShortcut.sequence = master.nextShortcutSequence(section: section)
        }
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

public class Master : ObservableObject {
    
    @Published public var sections: [SectionViewModel] = []
    @Published public var shortcuts: [ShortcutViewModel] = []
    
    init(sections: [SectionViewModel], shortcuts: [ShortcutViewModel]) {
        self.sections = sections
        self.shortcuts = shortcuts
    }
    
    public func nextSectionSequence() -> Int {
        return self.sections.map { $0.sequence }.reduce(0) {max($0, $1)} + 1
    }

    public func nextShortcutSequence(section: SectionViewModel) -> Int {
        return self.shortcuts.filter {$0.section == section.name}.map { $0.sequence }.reduce(0) {max($0, $1)} + 1
    }

    
}

var sections: [SectionViewModel] =
    [SectionViewModel(id: UUID(), name: "", sequence: 1),
     SectionViewModel(id: UUID(), name: "Bridge", sequence: 2),
     SectionViewModel(id: UUID(), name: "Models", sequence: 3),
     SectionViewModel(id: UUID(), name: "Whist", sequence: 4),
     SectionViewModel(id: UUID(), name: "Fishing", sequence: 5)]

var shortcuts: [ShortcutViewModel] =
[ ShortcutViewModel(id: UUID(), name: "Email", value: "marc@sheareronline.com", section: "", sequence: 1),
  ShortcutViewModel(id: UUID(), name: "Name", value: "Marc Shearer", section: "", sequence: 2),
  ShortcutViewModel(id: UUID(), name: "Hi Opps", value: "Hi opps - we're weak & benji", section: "Bridge", sequence: 1),
  ShortcutViewModel(id: UUID(), name: "Hi There", value: "Hi opps", section: "Bridge", sequence: 2),
  ShortcutViewModel(id: UUID(), name: "Please explain", value: "Please explain your partners last bid", section: "Bridge", sequence: 3)]

var master = Master(sections: sections, shortcuts: shortcuts)
