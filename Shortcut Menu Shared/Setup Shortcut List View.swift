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
                Spacer().frame(width: 10)
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
                    .font(.largeTitle)
                    .minimumScaleFactor(0.75)
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
                            panel = .detail
                        }
                    }
                }
                Spacer().frame(width: 5.0)
            }
            .frame(height: defaultRowHeight)
            .background(Palette.header.background)
            .foregroundColor(Palette.header.text)
            
            if selection.shortcuts.isEmpty {
                Tile(text: "No shortcuts defined", disabled: true)
            } else {
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
                List {
                    ForEach (selection.shortcuts, id: \.self.name) { (shortcut) in
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
                .padding(0)
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
                        panel = .detail
                    } else {
                        selection.selectSection(section: shortcut.nestedSection!)
                    }
                }
        })
        .listRowInsets(EdgeInsets())
    }
    
    func onInsertShortcutAction(to: Int, from: Int) {
        DispatchQueue.main.async {
            print("from: \(from) to: \(to)")
            selection.shortcuts.move(fromOffsets: [from], toOffset: to + (to > from && MyApp.target == .iOS ? 1 : 0))
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
