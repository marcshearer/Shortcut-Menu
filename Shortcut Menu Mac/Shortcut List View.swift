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
            .frame(width: shortcutWidth, height: rowHeight)
            .background(titleBackgroundColor)
            .foregroundColor(titleTextColor)
            /*if self.selection.shortcuts?.isEmpty ?? false {
                VStack{
                    HStack(alignment: .top) {
                        Spacer()
                        Text("No shortcuts defined")
                            .frame(width: shortcutWidth-10.0, height: rowHeight, alignment: .leading)
                            .foregroundColor(listMessageColor)
                            .font(defaultFont)
                    }
                    Spacer()
                }
            } else {*/
                List {
                    ForEach (self.selection.shortcuts) { (shortcut) in
                        if self.selection.editMode != .none {
                            self.shortcutRow(shortcut)
                        } else {
                            self.shortcutRow(shortcut)
                                .onDrag({shortcut.itemProvider})
                        }
                    }
                    .onInsert(of: ShortcutItemProvider.writableTypeIdentifiersForItemProvider) { (index, items) in
                        ShortcutItemProvider.dropAction(at: index, items, selection: self.selection, action: self.dropShortcutAction)
                    }
                }
                .opacity((self.selection.editMode != .none ? 0.2 : 1.0))
                .environment(\.defaultMinListRowHeight, rowHeight)
        }
    }
    
    fileprivate func shortcutRow(_ shortcut: ShortcutViewModel) -> some View {
        return Text(shortcut.name)
        .frame(width: shortcutWidth, height: rowHeight, alignment: .leading)
        .font(defaultFont)
        .listRowBackground((shortcut.id == self.selection.selectedShortcut?.id ? shortcutSelectionBackgroundColor : listBackgroundColor))
        .foregroundColor((shortcut.id == self.selection.selectedShortcut?.id ? shortcutSelectionTextColor : listTextColor))
        .contentShape(Rectangle())
        .onTapGesture {
            if self.selection.editMode == .none {
                self.selection.selectShortcut(shortcut: shortcut)
            }
        }
    }

    func dropShortcutAction(to: Int, from: Int) {
        DispatchQueue.main.async {
            self.selection.shortcuts.move(fromOffsets: [from], toOffset: to)
            self.selection.updateShortcutSequence()
        }
    }
}
