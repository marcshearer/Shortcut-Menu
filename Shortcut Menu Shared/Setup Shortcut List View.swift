//
//  ShortcutList.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct SetupShortcutListView: View {
    @ObservedObject public var selection: Selection
    @Binding public var panel: SetupPanel
    @State var width: CGFloat
    
    var body: some View {
                
        VStack(spacing: 0.0) {
            HStack {
                Spacer().frame(width: 16.00)
                if panel == .shortcuts {
                    Image(systemName: "arrow.turn.up.left")
                        .font(.title)
                        .onTapGesture {
                            if MasterData.shared.isNested(selection.selectedSection) {
                                selection.selectSection(section: MasterData.shared.nestedParent(selection.selectedSection))
                            } else {
                                panel = .sections
                            }
                        }
                }
                
                Text(selection.shortcutsTitle)
                    .font(defaultFont)
                    .minimumScaleFactor(0.75)
                Spacer()
                
                if selection.editAction == .none {
                    if selection.editObject != .none {
                        if let shortcut = MasterData.shared.shortcuts.first(where: {$0.nestedSection?.id == selection.selectedSection?.id}) {
                            // Nested section - add button to un-nest it
                            ToolbarButton("folder.fill.badge.minus") {
                                if let section = selection.selectedSection {
                                    selection.removeShortcut(shortcut: shortcut)
                                    if section.inline {
                                        // Can't be inline if not nested
                                        section.inline = false
                                        section.save()
                                    }
                                    selection.selectSection(section: section)
                                }
                            }
                        } else {
                            // Not nested add button to nest it
                            ToolbarButton("folder.fill.badge.plus") {
                                self.nestSection()
                            }
                        }
                    }
                    
                    if panel != .all {
                        ToolbarButton("pencil.circle.fill") {
                            selection.selectSection(section: selection.selectedSection)
                            selection.editAction = .amend
                            panel = .detail
                        }
                    }
                    
                    if panel == .all && selection.selectedShortcut != nil {
                        ToolbarButton("minus.circle.fill") {
                            selection.removeShortcut(shortcut: selection.selectedShortcut!)
                        }
                    }
                    
                    if selection.selectedSection != nil {
                        ToolbarButton("plus.circle.fill") {
                            selection.newShortcut(section: selection.selectedSection!)
                            if panel != .all {
                                panel = .detail
                            }
                        }
                    }
                }
                Spacer().frame(width: 5.0)
            }
            .frame(height: defaultRowHeight)
            .background(Palette.header.background)
            .foregroundColor(Palette.header.text)
            
            if MasterData.shared.isNested(selection.selectedSection) && panel == .all {
                Tile(leadingImageName: { "arrow.turn.up.left" },
                     dynamicText: {
                        MasterData.shared.nestedParent(selection.selectedSection)?.name ?? "Parent Section"
                     },
                     disabled: true,
                     tapAction: {
                            selection.selectSection(section: MasterData.shared.nestedParent(selection.selectedSection))
                     })
            }
            if selection.shortcuts.isEmpty {
                List {
                    ForEach(0..<1) { (index) in
                        Tile(text: "No shortcuts defined", disabled: true)
                    }
                    .onInsert(of: [SectionItemProvider.type.identifier, UTType.url.identifier])
                    { (index, items) in
                        // Allow insert in empty list
                        SectionItemProvider.dropAction(at: 0, items, selection: selection, action: self.onInsertSectionAction)
                        selection.dropUrl(afterIndex: 0, items: items)
                    }
                }
                .listStyle(PlainListStyle())
                .environment(\.defaultMinListRowHeight, defaultRowHeight)
            } else {
                List {
                    ForEach (selection.shortcuts, id: \.self.listHasher) { (shortcut) in
                        if selection.editAction != .none {
                            self.shortcutRow(shortcut)
                        } else {
                            self.shortcutRow(shortcut)
                                .onDrag({shortcut.itemProvider})
                        }
                    }
                    .onInsert(of: [ShortcutItemProvider.type.identifier, NestedSectionItemProvider.type.identifier, SectionItemProvider.type.identifier, UTType.url.identifier])
                    { (index, items) in
                        ShortcutItemProvider.dropAction(at: index, items, selection: selection, action: self.onInsertShortcutAction)
                        SectionItemProvider.dropAction(at: index, items, selection: selection, action: self.onInsertSectionAction)
                        selection.dropUrl(afterIndex: index, items: items)
                    }
                }
                .padding(.horizontal, 0) // Remove when bug fixed on Mac OS
                .listStyle(PlainListStyle())
                .environment(\.defaultMinListRowHeight, defaultRowHeight)
                .opacity((selection.editAction != .none ? 0.6 : 1.0))
            }
            Spacer()
        }
    }
    
    fileprivate func shortcutRow(_ shortcut: ShortcutViewModel) -> some View {
        let nested = (shortcut.nestedSection != nil)
        return Tile(leadingImageName: { (nested ? "folder" : nil) }, dynamicText: { shortcut.name }, trailingImageName: { shortcut.shared ? "icloud.and.arrow.up" : nil }, selected: { shortcut.id == selection.selectedShortcut?.id && panel == .all }, disabled: nested, tapAction: {
                if selection.editAction == .none {
                    if shortcut.type == .shortcut {
                        selection.selectShortcut(shortcut: shortcut)
                        if panel != .all {
                            panel = .detail
                        }
                    } else {
                        selection.selectSection(section: shortcut.nestedSection!)
                    }
                }
        })
        .listRowInsets(EdgeInsets())
    }
    
    func onInsertShortcutAction(to: Int, from: Int) {
        Utility.mainThread {
            print("from: \(from) to: \(to)")
            selection.shortcuts.move(fromOffsets: [from], toOffset: to + (to > from && MyApp.target == .iOS ? 1 : 0))
            selection.updateShortcutSequence()
        }
    }
    
    func onInsertSectionAction(to: Int, from: Int) {
        Utility.mainThread {
            if let currentSection = selection.selectedSection {
                let nestedSection = selection.sections[from]
                if currentSection.id != nestedSection.id {
                    selection.newNestedSectionShortcut(in: currentSection, to: nestedSection, at: to)
                    selection.selectSection(section: nestedSection, updateShortcuts: false)
                    selection.sections.remove(at: from)
                }
            }
        }
    }
    
    func nestSection() {
        let options = MasterData.shared.getSections(excludeSections: [selection.selectedSection!.name], excludeDefault: false, excludeNested: false).map{($0.isDefault ? defaultSectionMenuName : $0.name)}.sorted(by: {$0 < $1})
        
        SlideInMenu.shared.show(title: "Nest in Section", options: options) { (section) in
            if let targetSection = selection.getSection(name: ((section == defaultSectionMenuName ? "" : section)!)) {
                if let currentSection = selection.selectedSection {
                    selection.newNestedSectionShortcut(in: targetSection, to: currentSection)
                    selection.selectSection(section: targetSection)
                }
            }
        }
    }
}
