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
                                 rightContent: {expandButtons(entry: entry)},
                                 tapAction: {
                                    displayState.set(expanded: !entry.expanded, on: entry)
                                 }
                            )
                            
                        } else {
                            // Shortcut
                            Tile(text: entry.text,
                                 color: entry.color,
                                 selected: { displayState.selectedShortcut == entry.text },
                                 rounded: true,
                                 insets: EdgeInsets(top: 2,
                                                    leading: (10 + 22 * CGFloat(entry.depth)),
                                                    bottom: 2,
                                                    trailing: 12),
                                 tapAction: {
                                    shortcutAction(shortcut: entry.text)
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
                    .foregroundColor(entry.color.text)
                    .debugPrint("\(entry.text) \(entry.expanded)"))
    }
    
    func shortcutAction(shortcut name: String) {
        if let shortcut = MasterData.shared.shortcut(named: name) {
            displayState.selectedShortcut = shortcut.name
            var message = ""
            if shortcut.url != "" {
                message = "Linking to \(shortcut.name)...\n\n"
            }
            Actions.shortcut(name: shortcut.name) { (copyMessage) in
                if let copyMessage = copyMessage {
                    message += copyMessage
                }
                MessageBox.shared.show(message, closeButton: false, hideAfter: 3)
                Utility.executeAfter(delay: 3) {
                    displayState.selectedShortcut = nil
                }
            }
        }
    }
}

class DisplayStateViewModel: ObservableObject {
    
    class Entry: Identifiable, ObservableObject {
        var id: UUID
        @Published var type: ShortcutViewModel.ShortcutType
        @Published var text: String
        @Published var depth: Int
        @Published var expanded: Bool
        @Published var visible: Bool
        @Published var parent: Entry?
        
        public var color: PaletteColor { (type == .shortcut ? Palette.background :
                                         (depth == 0        ? Palette.header :
                                                              Palette.subHeader)) }
        
        init(type: ShortcutViewModel.ShortcutType, text: String, depth: Int, expanded: Bool = true, visible: Bool = true, parent: Entry? = nil) {
            self.id = UUID()
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
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
      
    init() {
        self.selectedSection = UserDefault.currentSection.string
        self.setupMappings()
    }
    
    public func set(expanded: Bool, on entry: Entry) {
        var changed = false
        for listEntry in list {
            if listEntry.id == entry.id {
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
    }
    
    private func setupList(section: String?) -> [Entry] {
        var list: [Entry] = []
        if selectedSection != nil {
            if selectedSection != "" {
                add(list: &list, section: selectedSection!)
            }
        }
        
        add(list: &list, section: "", depth: 0)
        
        let parent = add(list: &list, type: .section, text: "Other Shortcuts", depth: 0)
        for section in MasterData.shared.sectionsWithShortcuts(excludeSections: ["", selectedSection ?? ""], excludeNested: true) {
            add(list: &list, section: section, depth: 1, expanded: false, parent: parent)
        }
        return list
    }
    
    private func add(list: inout [Entry], section name: String, depth: Int = 0, header: Bool = true) {
        if let section = MasterData.shared.section(named: name) {
            add(list: &list, section: section, depth: depth, header: header)
        }
    }
    
    private func add(list: inout [Entry], section: SectionViewModel, depth: Int = 0, expanded: Bool = true, header: Bool = true, parent: Entry? = nil) {
        var parent = parent
        
        if header {
            parent = add(list: &list, type: .section, text: section.name, depth: depth, expanded: expanded, visible: depth <= 1, parent: parent)
        }
        
        for shortcut in section.shortcuts {
            if shortcut.type == .section {
                if let nestedSection = shortcut.nestedSection {
                    add(list: &list, section: nestedSection, depth: depth + 1, expanded: false, parent: parent)
                }
            } else {
                add(list: &list, type: .shortcut, text: shortcut.name, depth: depth + 1, visible: depth == 0, parent: parent)
            }
        }
    }
    
    @discardableResult private func add(list: inout [Entry], type: ShortcutViewModel.ShortcutType, text: String, depth: Int, expanded: Bool =  true, visible: Bool = true, parent: Entry? = nil) -> Entry {
        let entry = Entry(type: type, text: text, depth: depth, expanded: expanded, visible: visible, parent: parent)
        list.append(entry)
        return entry
    }
}
