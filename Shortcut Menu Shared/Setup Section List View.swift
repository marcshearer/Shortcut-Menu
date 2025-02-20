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
    @Binding public var panel: SetupPanel
    @State var width: CGFloat
    
    var body: some View {
        GeometryReader { (geometry) in
            VStack(spacing: 0.0) {
                
                sectionHeading()
                
                List {
                    ForEach (self.selection.sections, id: \.self.listHasher) { (section) in
                        if section.isDefault || self.selection.editAction != .none {
                            self.sectionRow(section)
                        } else {
                            self.sectionRow(section)
                                .onDrag({section.itemProvider})
                        }
                    }
                    .onInsert(of: [SectionItemProvider.type.identifier,
                                   NestedSectionItemProvider.type.identifier])
                    { (index, items) in
                        SectionItemProvider.dropAction(at: index, items, selection: self.selection, action: self.onInsertSectionAction)
                        NestedSectionItemProvider.dropAction(at: index, items, selection: self.selection, action: self.onInsertNestedSectionAction)
                    }
                }
                .padding(.horizontal, 0)
                .listStyle(PlainListStyle())
                .environment(\.defaultMinListRowHeight, defaultRowHeight)
                .opacity((self.selection.editAction != .none ? 0.6 : 1.0))
                Spacer()
            }
        }
    }
    
    private func sectionRow(_ section: SectionViewModel) -> some View {
        Tile(dynamicText: { section.displayName }, trailingImageName: { section.shared ? "icloud.and.arrow.up" : nil }, selected: { (section.id == self.selection.selectedSection?.id) && panel == .all }, disabled: section.isDefault, tapAction: {
            if self.selection.editAction == .none {
                self.selection.selectSection(section: section)
            }
            if panel != .all {
                panel = .shortcuts
            }
        })
        .onDrop(of: [ShortcutItemProvider.type.identifier, UTType.url.identifier, UTType.fileURL.identifier], delegate: SectionListDropDelegate(self, id: section.id))
        .listRowInsets(EdgeInsets(top: (MyApp.target == .macOS ? 4 : 0), leading: 0, bottom: (MyApp.target == .macOS ? 4 : 0), trailing: 0))
    }
    
    private func sectionHeading() -> some View {
        ZStack {
            Tile(text: "Sections", color: Palette.header)
            
            HStack{
                Spacer()
                if self.selection.editAction == .none {
                    if let section = self.selection.selectedSection, (panel == .all && !section.isDefault) {
                        ToolbarButton("minus.circle.fill") {
                            MessageBox.shared.show("You are deleting a section that contains shortcuts!\n\n If you delete it then the section and all its shortcuts will be removed.", if: {!section.shortcuts.isEmpty}, buttons: .confirmCancel, icon: "exclamationmark.triangle") { (confirmed) in
                                if confirmed {
                                    selection.removeSection(section: section)
                                }
                            }
                        }
                    }
                    
                    ToolbarButton("plus.circle.fill") {
                        self.selection.newSection()
                        if panel != .all {
                            panel = .detail
                        }
                    }
                }
                Spacer().frame(width: 5.0)
            }
        }
        .frame(height: defaultRowHeight)
        .background(Palette.header.background)
        .foregroundColor(Palette.header.text)
    }
    
    private func onInsertSectionAction(at: Int, section: SectionViewModel) {
        Utility.mainThread {
            if at > 0 {
                if let fromIndex = selection.sections.firstIndex(where: {$0.id == section.id}) {
                    self.selection.sections.move(fromOffsets: [fromIndex], toOffset: at + (at > fromIndex && MyApp.target == .iOS ? 1 : 0))
                    self.selection.updateSectionSequence()
                }
            }
        }
    }
        
    private func onInsertNestedSectionAction(at: Int, shortcut: ShortcutViewModel) {
        Utility.mainThread {
            if shortcut.action == .nestedSection {
                // Remove section link shortcut
                self.selection.removeShortcut(shortcut: shortcut)
                
                // Insert the section at the drop location
                if let section = shortcut.nestedSection {
                    self.selection.sections.insert(section, at: at)
                    self.selection.updateSectionSequence()
                }
            }
        }
    }

    public func onDropShortcutAction(at: Int, shortcut: ShortcutViewModel) {
        Utility.mainThread {
            shortcut.section = self.selection.sections[at]
            shortcut.sequence = MasterData.shared.nextShortcutSequence(section: self.selection.sections[at])
            shortcut.save()
            self.selection.deselectShortcut()
            self.selection.selectSection(section: self.selection.selectedSection!)
            self.selection.updateShortcutSequence()
        }
    }
}
