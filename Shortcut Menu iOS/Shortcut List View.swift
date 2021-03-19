//
//  Sections.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 08/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI
import Combine

struct ShortcutListView: View {
    @ObservedObject var displayState: DisplayStateViewModel
    @State var data = MasterData.shared
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(displayState.list) { (entry) in
                    if entry.visible {
                        if entry.type == .section {
                            // Section
                            Tile(dynamicText: {entry.text == "" ? "Default Shortcuts" : entry.text},
                                 color: entry.color,
                                 rounded: true,
                                 insets: EdgeInsets(top: entry.depth == 0 ? 10 : 2,
                                                    leading: (10 + 22 * CGFloat(entry.depth)),
                                                    bottom: 2,
                                                    trailing: 10),
                                 trailingContent: {expandButtons(entry: entry)},
                                 tapAction: {
                                    displayState.set(expanded: !entry.expanded, on: entry)
                                 }
                            )
                            
                        } else {
                            // Shortcut
                            Tile(dynamicText: {entry.text},
                                 color: entry.color,
                                 selected: { displayState.selectedShortcut == entry.text },
                                 rounded: true,
                                 insets: EdgeInsets(top: 2,
                                                    leading: (10 + 22 * CGFloat(entry.depth)),
                                                    bottom: 2,
                                                    trailing: 12),
                                 tapAction: {
                                    if let linkId = entry.linkId, let shortcut = MasterData.shared.shortcut(withId: linkId) {
                                        shortcutAction(shortcut: shortcut)
                                    }
                                 })
                        }
                    }
                }
            }
        }
    }
    
    func expandButtons(entry: DisplayStateViewModel.Entry) -> AnyView {
            return AnyView(Image(systemName: "chevron.\(entry.expanded ? "down" : "forward").circle.fill")
                    .font(defaultFont)
                    .foregroundColor(entry.color.text))
    }
    
    func shortcutAction(shortcut: ShortcutViewModel) {
        displayState.selectedShortcut = shortcut.name
        var message = ""
        if shortcut.url != "" {
            message = "Linking to\n\(shortcut.name)...\n\n"
        }
        Actions.shortcut(name: shortcut.name) { (copyMessage) in
            if let copyMessage = copyMessage {
                message += copyMessage
            }
            MessageBox.shared.show(message, fontSize: 24, closeButton: false, hideAfter: 3)
            Utility.executeAfter(delay: 3) {
                displayState.selectedShortcut = nil
            }
        }
    }
}

class DisplayStateViewModel: ObservableObject {
    
    class Entry: Identifiable, ObservableObject {
        internal var id = UUID()
        @Published var type: ShortcutType
        @Published var linkId: UUID?
        @Published var text: String
        @Published var depth: Int
        @Published var expanded: Bool
        @Published var visible: Bool
        @Published var parent: Entry?
        
        public var color: PaletteColor { (type == .shortcut ? Palette.background :
                                         (depth == 0        ? Palette.header :
                                                              Palette.subHeader)) }
        
        init(type: ShortcutType, linkId: UUID?, text: String, depth: Int, expanded: Bool = true, visible: Bool = true, parent: Entry? = nil) {
            self.linkId = linkId
            self.type = type
            self.text = text
            self.depth = depth
            self.expanded = expanded
            self.visible = visible
            self.parent = parent
        }
    }
    
    @Published var selectedSection: String?
    @Published var selectedShortcut: String?
    @Published var list: [Entry] = []
    @Published var displayedRemoteUpdates = 0
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
      
    init() {
        self.selectedSection = UserDefault.currentSection.string
        self.setupMappings()
    }
    
    public func set(expanded: Bool, on entry: Entry) {
        var changed = false
        for listEntry in list {
            if listEntry.linkId == entry.linkId {
                if entry.expanded != expanded {
                    entry.expanded = expanded
                    changed = true
                }
            } else {
                var newValue: Bool
                if let parent = listEntry.parent {
                    newValue = (parent.expanded && parent.visible)
                } else {
                    newValue =  true
                }
                if listEntry.visible != newValue {
                    listEntry.visible = newValue
                    changed = true
                }
            }
        }
        if changed {
            // Notify change of publisher
            self.objectWillChange.send()
        }
    }
    
    private func setupMappings() {
        $selectedSection
            .receive(on: RunLoop.main)
            .map { (selectedSection) in
                return (self.setupList(section: selectedSection))
            }
        .assign(to: \.list, on: self)
        .store(in: &cancellableSet)
        
        $displayedRemoteUpdates
            .receive(on: RunLoop.main)
            .map { (publishedRemoteUpdates) in
                return (publishedRemoteUpdates)
            }
            .sink(receiveValue: { (newValue) in
                self.refreshNames()
            })
        .store(in: &cancellableSet)
    }
    
    private func refreshNames() {
        var changed = false
        for entry in list {
            if let linkId = entry.linkId {
                switch entry.type {
                case .section:
                    if let section = MasterData.shared.section(withId: linkId) {
                        if entry.text != section.name {
                            entry.text = section.name
                            changed = true
                        }
                    }
                case .shortcut:
                    if let shortcut = MasterData.shared.shortcut(withId: linkId) {
                        if entry.text != shortcut.name {
                            entry.text = shortcut.name
                            changed = true
                        }
                    }
                }
            }
        }
        if changed {
            self.objectWillChange.send()
        }
    }
    
    public func refreshList() {
        self.list = self.setupList(section: selectedSection)
    }
    
    private func setupList(section: String?) -> [Entry] {
        var list: [Entry] = []
        if let section = section {
            if let selectedSection = MasterData.shared.section(named: section) {
                if !selectedSection.isDefault {
                    add(list: &list, section: selectedSection)
                }
            }
        }
        
        if let defaultSection = MasterData.shared.defaultSection {
            add(list: &list, section: defaultSection)
        }
        
        let parent = add(list: &list, type: .section, id: nil, text: "Other Shortcuts", depth: 0)
        for section in MasterData.shared.sectionsWithShortcuts(excludeSections: [selectedSection ?? ""], excludeDefault: true, excludeNested: true) {
            add(list: &list, section: section, depth: 1, expanded: false, parent: parent)
        }
        return list
    }
    
    private func add(list: inout [Entry], section: SectionViewModel, depth: Int = 0, expanded: Bool = true, header: Bool = true, parent: Entry? = nil) {
        var parent = parent
        let shortcuts = section.shortcuts
        var depth = depth
        var expanded = expanded
        
        if shortcuts.count > 0 {
            
            if header && shortcuts.count > 1 {
                parent = add(list: &list, type: .section, id: section.id, text: section.name, depth: depth, expanded: expanded, visible: depth <= 1 || section.shortcuts.count == 1, parent: parent)
                depth += 1
            } else {
                expanded = true
            }
            
            for shortcut in shortcuts {
                if shortcut.type == .section {
                    if let nestedSection = shortcut.nestedSection {
                        add(list: &list, section: nestedSection, depth: depth, expanded: false, parent: parent)
                    }
                } else {
                    add(list: &list, type: .shortcut, id: shortcut.id, text: shortcut.name, depth: depth, expanded: expanded, visible: expanded, parent: parent)
                }
            }
        }
    }
    
    @discardableResult private func add(list: inout [Entry], type: ShortcutType, id: UUID?, text: String, depth: Int, expanded: Bool =  true, visible: Bool = true, parent: Entry? = nil) -> Entry {
        let entry = Entry(type: type, linkId: id, text: text, depth: depth, expanded: expanded, visible: visible, parent: parent)
        list.append(entry)
        return entry
    }
}
