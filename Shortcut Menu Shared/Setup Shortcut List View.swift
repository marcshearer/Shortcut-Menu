//
//  ShortcutList.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct SetupShortcutListView: View {
    @ObservedObject public var selection: Selection

    @State var width: CGFloat
    
    var body: some View {
                
        VStack(spacing: 0.0) {
            ZStack {
                Tile(dynamicText: { selection.shortcutsTitle }, color: Palette.header)
                
                HStack(spacing: 0.0) {
                    Spacer()
                    if selection.editAction == .none {
                        if selection.selectedShortcut != nil {
                            ToolbarButton("minus.circle.fill") {
                                selection.removeShortcut(shortcut: selection.selectedShortcut!)
                            }
                        }
                        
                        if selection.selectedSection != nil {
                            ToolbarButton("plus.circle.fill") {
                                selection.newShortcut(section: selection.selectedSection!)
                            }
                        }
                    }
                    Spacer().frame(width: 5.0)
                }
            }
            if selection.shortcuts.isEmpty {
                Tile(text: "No shortcuts defined", disabled: true)
            } else {
                List {
                    ForEach (selection.shortcuts) { (shortcut) in
                        if selection.editAction != .none {
                            self.shortcutRow(shortcut)
                        } else {
                            self.shortcutRow(shortcut)
                                .onDrag({shortcut.itemProvider})
                        }
                    }
                    .onMove(perform: { indices, newOffset in
                        self.onMoveAction(to: newOffset, from: indices)
                    })
                    .onInsert(of: [SectionItemProvider.type.identifier])
                    { (index, items) in
                        SectionItemProvider.dropAction(at: index, items, selection: selection, action: self.onInsertSectionAction)
                    }
                    .listRowInsets(EdgeInsets())
                }
                .moveDisabled(false)
                .opacity((selection.editAction != .none ? 0.6 : 1.0))
                .environment(\.defaultMinListRowHeight, defaultRowHeight)
            }
            Spacer()
        }
    }
    
    fileprivate func shortcutRow(_ shortcut: ShortcutViewModel) -> some View {
        Tile(text: shortcut.name, selected: { shortcut.id == selection.selectedShortcut?.id }, nested: shortcut.nestedSection != nil) {
            if selection.editAction == .none {
                if shortcut.type == .shortcut {
                    selection.selectShortcut(shortcut: shortcut)
                } else {
                    selection.selectSection(section: shortcut.nestedSection!)
                }
            }
        }
    }
    
    func onMoveAction(to: Int, from: IndexSet) {
        DispatchQueue.main.async {
            selection.shortcuts.move(fromOffsets: from, toOffset: to)
            selection.updateShortcutSequence()
        }
    }
    
    func onInsertSectionAction(to: Int, from: Int) {
        DispatchQueue.main.async {
            if let currentSection = selection.selectedSection {
                let nestedSection = selection.sections[from]
                if currentSection.id != nestedSection.id {
                    selection.newNestedSectionShortcut(in: currentSection, to: nestedSection, at: to)
                }
            }
        }
    }
}
