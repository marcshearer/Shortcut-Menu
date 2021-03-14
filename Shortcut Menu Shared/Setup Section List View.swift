//
//  SectionList.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

struct SetupSectionListView: View {
    @ObservedObject public var selection: Selection
     
    @State var width: CGFloat
    
    var body: some View {
        let master = MasterData.shared

        GeometryReader { (geometry) in
            VStack(spacing: 0.0) {
                ZStack {
                    Tile(text: "Sections", color: Palette.header)
                    
                    HStack{
                        Spacer()
                        if self.selection.editAction == .none {
                            if self.selection.selectedSection != nil && !(self.selection.selectedSection?.isDefault ?? true) {
                                ToolbarButton("minus.circle.fill") {
                                    self.selection.removeSection(section: self.selection.selectedSection!)
                                }
                            }
                            
                            ToolbarButton("plus.circle.fill") {
                                self.selection.newSection()
                            }
                        }
                        Spacer().frame(width: 5.0)
                    }
                }
                .frame(height: defaultRowHeight)
                .background(Palette.header.background)
                .foregroundColor(Palette.header.text)
                List {
                    ForEach (self.selection.sections) { (section) in
                        if !master.isNested(section) {
                            if section.isDefault || self.selection.editAction != .none {
                                self.sectionRow(section)
                            } else {
                                self.sectionRow(section)
                                    .onDrag({section.itemProvider})
                            }
                        }
                    }
                    .onInsert(of: [SectionItemProvider.type.identifier, NestedSectionItemProvider.type.identifier])
                    { (index, items) in
                        SectionItemProvider.dropAction(at: index, items, selection: self.selection, action: self.onInsertSectionAction)
                        NestedSectionItemProvider.dropAction(at: index, items, selection: self.selection, action: self.onInsertNestedSectionAction)
                    }
                    Spacer()
                }
                .listStyle(PlainListStyle())
                .environment(\.defaultMinListRowHeight, defaultRowHeight)
                .opacity((self.selection.editAction != .none ? 0.6 : 1.0))
            }
        }
    }
    
    fileprivate func sectionRow(_ section: SectionViewModel) -> some View {
        Tile(text: section.displayName, selected: { (section.id == self.selection.selectedSection?.id) }, disabled: section.isDefault, tapAction: {
            if self.selection.editAction == .none {
                self.selection.selectSection(section: section)
            }
        })
        .onDrop(of: [ShortcutItemProvider.type.identifier, UTType.url.identifier, UTType.fileURL.identifier], delegate: SectionListDropDelegate(self, id: section.id))
        .listRowInsets(EdgeInsets(top: (MyApp.target == .macOS ? 4 : 0), leading: 0, bottom: (MyApp.target == .macOS ? 4 : 0), trailing: 0))
    }
    
    func onInsertSectionAction(to: Int, from: Int) {
        DispatchQueue.main.async {
            if to > 0 {
                self.selection.sections.move(fromOffsets: [from], toOffset: to + (to > from ? 1 : 0))
                self.selection.updateSectionSequence()
            }
        }
    }
        
    func onInsertNestedSectionAction(to: Int, from: Int) {
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

    func onDropShortcutAction(to: Int, from: Int) {
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