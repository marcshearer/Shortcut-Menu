//
//  ShortcutList.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct SetupShortcutListView: View, DropDelegate {
    
    @ObservedObject public var selection: Selection
    @Binding public var panel: SetupPanel
    @State var width: CGFloat
    @State var singleSection = false
    @State private var parentSectionIsEntered = false
    
    var body: some View {
                
        VStack(spacing: 0.0) {
            
            shortcutHeading()
            
            if MasterData.shared.isNested(selection.selectedSection) && panel == .all {
                Tile(leadingImageName: { "arrow.turn.up.left" },
                     dynamicText: {
                        MasterData.shared.nestedParent(selection.selectedSection)?.name ?? "Parent Section"
                     },
                     disabled: true,
                     tapAction: {
                            selection.selectSection(section: MasterData.shared.nestedParent(selection.selectedSection))
                     })
                .onDrop(of: [ShortcutItemProvider.type.identifier, UTType.url.identifier, UTType.fileURL.identifier], delegate: self)
            }
            if selection.shortcuts.isEmpty {
                List {
                    ForEach(0..<1) { (index) in
                        Tile(text: "No shortcuts defined", disabled: true)
                    }
                    .onInsert(of: [SectionItemProvider.type.identifier, ShortcutItemProvider.type.identifier, UTType.url.identifier, UTType.text.identifier]) { (index, items) in
                            // Allow insert in empty list
                        SectionItemProvider.dropAction(at: 0, items, selection: selection, action: self.onInsertSectionAction)
                        ShortcutItemProvider.dropAction(at: 0, items, selection: selection, action: self.onInsertShortcutAction)
                        selection.dropUrl(afterIndex: 0, items: items)
                        selection.dropString(afterIndex: 0, items: items)
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
                    .onInsert(of: [ShortcutItemProvider.type.identifier, NestedSectionItemProvider.type.identifier, SectionItemProvider.type.identifier, UTType.url.identifier, UTType.text.identifier])
                    { (index, items) in
                        ShortcutItemProvider.dropAction(at: index, items, selection: selection, action: self.onInsertShortcutAction)
                        SectionItemProvider.dropAction(at: index, items, selection: selection, action: self.onInsertSectionAction)
                        selection.dropUrl(afterIndex: index, items: items)
                        selection.dropString(afterIndex: index, items: items)
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
    
    private func shortcutRow(_ shortcut: ShortcutViewModel) -> some View {
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
        .onDrop(of: [ShortcutItemProvider.type.identifier, UTType.url.identifier, UTType.fileURL.identifier], delegate: ShortcutListDropDelegate(self, id: shortcut.id))
        .listRowInsets(EdgeInsets(top: (MyApp.target == .macOS ? 4 : 0), leading: 0, bottom: (MyApp.target == .macOS ? 4 : 0), trailing: 0))
    }
    
    private func shortcutHeading() -> some View {
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
            
            toolbarButtons()
            
            Spacer().frame(width: 5.0)
        }
        .frame(height: defaultRowHeight)
        .background(Palette.header.background)
        .foregroundColor(Palette.header.text)
    }
    
    private func toolbarButtons() -> some View {
        HStack {
            if selection.editAction == .none {
                if selection.editObject != .none && !singleSection {
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
                
                if selection.selectedSection != nil && !singleSection {
                    ToolbarButton("plus.circle.fill") {
                        selection.newShortcut(section: selection.selectedSection!)
                        if panel != .all {
                            panel = .detail
                        }
                    }
                }
            }
        }
    }
    
    func onInsertShortcutAction(at toIndex: Int, shortcut: ShortcutViewModel) {
        Utility.mainThread {
            if let fromIndex = selection.shortcuts.firstIndex(where: {$0.id == shortcut.id}) {
                // Short cut is in displayed list
                selection.shortcuts.move(fromOffsets: [fromIndex], toOffset: toIndex + (toIndex > fromIndex && MyApp.target == .iOS ? 1 : 0))
            } else {
                // Come from a different section
                selection.shortcuts.insert(shortcut, at: toIndex)
                shortcut.section = selection.selectedSection
                shortcut.save()
            }
            selection.updateShortcutSequence()
        }
    }
    
    func onInsertSectionAction(at: Int, section: SectionViewModel) {
        Utility.mainThread {
            if let currentSection = selection.selectedSection {
                if let fromIndex = selection.sections.firstIndex(where: {$0.id == section.id}) {
                    let nestedSection = selection.sections[fromIndex]
                    if currentSection.id != nestedSection.id {
                        selection.newNestedSectionShortcut(in: currentSection, to: nestedSection, at: at)
                        selection.selectSection(section: nestedSection, updateShortcuts: false)
                        selection.sections.remove(at: fromIndex)
                    }
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
    
    func performDrop(info: DropInfo) -> Bool {
        return false
    }
    
    func dropEntered(info: DropInfo) {
        // Move to parent being hovered over with a drop payload
        Utility.mainThread {
            self.parentSectionIsEntered = true
            Utility.executeAfter(delay: directoryHoverDelay) {
                if self.parentSectionIsEntered {
                    selection.selectSection(section: MasterData.shared.nestedParent(selection.selectedSection))
                }
            }
        }
    }
    
    func dropExited(info: DropInfo) {
        // Move to parent no longer being hovered over
        Utility.mainThread {
            self.parentSectionIsEntered = false
        }
    }
}
