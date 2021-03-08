//
//  SectionList.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct SectionListView: View {
    
    @ObservedObject public var selection: Selection
    
    @State var width: CGFloat
    
    var body: some View {
        let master = MasterData.shared

        VStack(spacing: 0.0) {
            HStack(spacing: 0.0) {
                Spacer()
                    .frame(width: 10.0)
                
                Text("Sections")
                    .font(defaultFont)
                
                Spacer()
                
                if self.selection.editMode == .none {
                    if self.selection.selectedSection != nil && self.selection.selectedSection?.name != "" {
                        ToolbarButton("minus.circle.fill") {
                            self.selection.removeSection(section: self.selection.selectedSection!)
                        }
                    }
                    
                    ToolbarButton("plus.circle.fill") {
                        self.selection.newSection()
                    }
                }
                
                Spacer()
                    .frame(width: 5.0)
            }
            .frame(height: defaultRowHeight)
            .background(Palette.header.background)
            .foregroundColor(Palette.header.text)
            ScrollView {
                VStack {
                    ForEach (self.selection.sections) { (section) in
                        let nested = master.shortcuts.firstIndex(where: { $0.type == .section && $0.nestedSection?.id == section.id })
                        if nested == nil {
                            if section.name == "" || self.selection.editMode != .none {
                                self.sectionRow(section)
                            } else {
                                self.sectionRow(section)
                                    .onDrag({section.itemProvider})
                            }
                        }
                    }
                    .onInsert(of: SectionItemProvider.writableTypeIdentifiersForItemProvider) { (index, items) in
                        if index != 0 {
                            SectionItemProvider.dropAction(at: index, items, selection: self.selection, action: self.insertSectionAction)
                            ShortcutItemProvider.dropAction(at: index, items, selection: self.selection, action: self.insertShortcutAction)
                        }
                    }
                }
                .opacity((self.selection.editMode != .none ? 0.6 : 1.0))
                .environment(\.defaultMinListRowHeight, defaultRowHeight)
            }
            .frame(width: width)
        }
        .moveDisabled(false)
    }
    
    fileprivate func sectionRow(_ section: SectionViewModel) -> some View {
        return
            HStack {
                Text(section.displayName)
                    .padding([.leading, .trailing], 16)
                    .frame(height: defaultRowHeight, alignment: .leading)
                    .font(defaultFont)
                    .foregroundColor((section.id == self.selection.selectedSection?.id ? Palette.selectedList.text : (section.name == "" ? Palette.selectedList.faintText : Palette.unselectedList.text)))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if self.selection.editMode == .none {
                            self.selection.selectSection(section: section)
                        }
                    }
                    .onDrop(of: ShortcutItemProvider.readableTypeIdentifiersForItemProvider, delegate: SectionListDropDelegate(self, id: section.id))
                Spacer()
            }
            .background((section.id == self.selection.selectedSection?.id ? Palette.selectedList.background : Palette.unselectedList.background))
    }
    
    func insertSectionAction(to: Int, from: Int) {
        DispatchQueue.main.async {
            self.selection.sections.move(fromOffsets: [from], toOffset: to)
            self.selection.updateSectionSequence()
        }
    }
        
    func insertShortcutAction(to: Int, from: Int) {
        DispatchQueue.main.async {
            let shortcut = self.selection.shortcuts[from]
            if shortcut.type == .section {
                // Remove section link shortcut
                self.selection.removeShortcut(shortcut: shortcut)
                
                // Find the section and move it to the drop location
                if let sectionIndex = self.selection.sections.firstIndex(where: {$0.name == shortcut.name}) {
                    self.selection.sections.move(fromOffsets: [sectionIndex], toOffset: to)
                    self.selection.updateSectionSequence()
                }
            }
        }
    }

    func dropShortcutAction(to: Int, from: Int) {
        DispatchQueue.main.async {
            self.selection.shortcuts[from].section = self.selection.sections[to]
            self.selection.shortcuts[from].sequence = MasterData.shared.nextShortcutSequence(section: self.selection.sections[to])
            self.selection.shortcuts[from].save()
            self.selection.deselectShortcut()
            self.selection.selectSection(section: self.selection.selectedSection!)
            self.selection.updateShortcutSequence()
        }
    }
}
