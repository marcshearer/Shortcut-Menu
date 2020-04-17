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
    @Published public var shortcuts: [ShortcutViewModel]?
    @Published public var shortcutsTitle: String = "No Section Selected"
    @Published public var selectedShortcut: ShortcutViewModel?
    
    init(master: Master) {
        self.master = master
        self.sections = master.sections
    }
    
    func selectSection(section: SectionViewModel) -> Bool {
        
        self.selectedShortcut = nil
        
        self.selectedSection = self.sections.first(where: {$0.id == section.id})
        if self.selectedSection != nil {
            self.shortcuts = self.master.shortcuts.filter { $0.section == self.selectedSection?.name}
            self.shortcutsTitle = self.selectedSection!.name
        } else {
            self.shortcuts = nil
            self.shortcutsTitle = "So Section Selected"
        }
        
        return (self.selectedSection != nil)
    
    }
    
    func selectShortcut(shortcut: ShortcutViewModel) -> Bool {
        
        self.selectedShortcut = self.shortcuts?.first(where: {$0.id == shortcut.id})
        
        return (self.selectedShortcut != nil)
    }
    
    func getSection(id: UUID) -> SectionViewModel? {
        return self.sections.first(where: { $0.id == id })
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
}

var sections: [SectionViewModel] =
    [SectionViewModel(id: UUID(), name: "No section", sequence: 1),
     SectionViewModel(id: UUID(), name: "Bridge", sequence: 2),
     SectionViewModel(id: UUID(), name: "Models", sequence: 3),
     SectionViewModel(id: UUID(), name: "Whist", sequence: 4),
     SectionViewModel(id: UUID(), name: "Fishing", sequence: 5)]

var shortcuts: [ShortcutViewModel] =
[ ShortcutViewModel(id: UUID(), name: "Hi Opps", value: "Hi opps - we're weak & benji", section: "Bridge", sequence: 1),
  ShortcutViewModel(id: UUID(), name: "Hi Opps", value: "Hi opps", section: "Bridge", sequence: 2),
  ShortcutViewModel(id: UUID(), name: "Please explain", value: "Please explain your partners last bid", section: "Bridge", sequence: 3)]

var master = Master(sections: sections, shortcuts: shortcuts)
