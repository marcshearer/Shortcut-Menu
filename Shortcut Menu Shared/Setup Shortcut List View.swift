//
//  ShortcutList.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct ShortcutListView: View {
    @ObservedObject public var selection: Selection

    @State var width: CGFloat
    
    var body: some View {
                
        VStack(spacing: 0.0) {
            HStack(spacing: 0.0) {
                Spacer()
                    .frame(width: 10.0)
                
                Text(self.selection.shortcutsTitle)
                    .font(defaultFont)
                
                Spacer()
                
                if self.selection.editMode == .none {
                    if self.selection.selectedShortcut != nil {
                        ToolbarButton("minus.circle.fill") {
                            self.selection.removeShortcut(shortcut: self.selection.selectedShortcut!)
                        }
                    }
                    
                    if self.selection.selectedSection != nil {
                        ToolbarButton("plus.circle.fill") {
                            self.selection.newShortcut(section: self.selection.selectedSection!)
                        }
                    }
                }
                
                Spacer()
                    .frame(width: 5.0)
            }
            .frame(height: defaultRowHeight)
            .background(Palette.header.background)
            .foregroundColor(Palette.header.text)
            if self.selection.shortcuts.isEmpty {
                VStack {
                    HStack(alignment: .top) {
                        Spacer().frame(width: 20)
                        Text("No shortcuts defined")
                            .frame(height: defaultRowHeight, alignment: .leading)
                            .foregroundColor(Palette.unselectedList.faintText)
                            .font(defaultFont)
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack {
                        ForEach (self.selection.shortcuts) { (shortcut) in
                            if self.selection.editMode != .none {
                                self.shortcutRow(shortcut)
                            } else {
                                self.shortcutRow(shortcut)
                                    .onDrag({shortcut.itemProvider})
                            }
                        }
                        .onInsert(of: ShortcutItemProvider.writableTypeIdentifiersForItemProvider) { (index, items) in
                            // Try both shortcut and section (only one should work)
                            ShortcutItemProvider.dropAction(at: index, items, selection: self.selection, action: self.dropShortcutAction)
                            SectionItemProvider.dropAction(at: index, items, selection: self.selection, action: self.dropSectionAction)
                        }
                    }
                    .opacity((self.selection.editMode != .none ? 0.6 : 1.0))
                    .environment(\.defaultMinListRowHeight, defaultRowHeight)
                }
                .frame(width: width)
            }
        }
        .moveDisabled(false)
    }
    
    fileprivate func shortcutRow(_ shortcut: ShortcutViewModel) -> some View {
        return
            HStack {
                if shortcut.type == .section {
                    Spacer().frame(width: 16)
                    Image(systemName: "link.circle.fill").foregroundColor(shortcut.id == self.selection.selectedShortcut?.id ? Palette.selectedList.text :Palette.selectedList.faintText).font(defaultFont)
                    Spacer().frame(width: 10)
                }
                Text(shortcut.name)
                    .padding([.leading, .trailing], 16)
                    .frame(height: defaultRowHeight, alignment: .leading)
                    .font(defaultFont)
                    .foregroundColor((shortcut.id == self.selection.selectedShortcut?.id ? Palette.selectedList.text : (shortcut.type == .section ? Palette.selectedList.faintText : Palette.unselectedList.text)))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if self.selection.editMode == .none {
                            if shortcut.type == .shortcut {
                                self.selection.selectShortcut(shortcut: shortcut)
                            } else {
                                self.selection.selectSection(section: shortcut.nestedSection!)
                            }
                        }
                    }
                Spacer()
            }
            .background(shortcut.id == self.selection.selectedShortcut?.id ? Palette.selectedList.background : Palette.unselectedList.background)
    }
    
    func dropShortcutAction(to: Int, from: Int) {
        DispatchQueue.main.async {
            self.selection.shortcuts.move(fromOffsets: [from], toOffset: to)
            self.selection.updateShortcutSequence()
        }
    }
    
    func dropSectionAction(to: Int, from: Int) {
        DispatchQueue.main.async {
            if let currentSection = self.selection.selectedSection {
                let nestedSection = self.selection.sections[from]
                if currentSection.id != nestedSection.id {
                    self.selection.newNestedSectionShortcut(in: currentSection, to: nestedSection, at: to)
                }
            }
        }
    }
}
