//
//  ShortcutList.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct ShortcutList: View {
    
    @ObservedObject private var selection: Selection
    
    init(selection: Selection) {
        self.selection = selection
    }
    
    var body: some View {
                
        VStack(spacing: 0.0) {
            HStack {
                Spacer()
                    .frame(width: 10.0)
                Text(self.selection.shortcutsTitle)
                    .font(defaultFont)
                Spacer()
                Image("arrow.up.arrow.down.circle.fill")
                Spacer()
                    .frame(width: 5.0)
            }
            .frame(width: shortcutWidth, height: rowHeight)
            .background(titleBackgroundColor)
            .foregroundColor(titleTextColor)
            if self.selection.shortcuts?.isEmpty ?? false {
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
            } else {
                List {
                    ForEach (self.selection.shortcuts ?? []) { (shortcut) in
                            Text(shortcut.name)
                                .frame(width: shortcutWidth, height: rowHeight, alignment: .leading)
                                .font(defaultFont)
                                .onTapGesture {
                                    _ = self.selection.selectShortcut(shortcut: shortcut)
                                }
                            .listRowBackground((shortcut.id == self.selection.selectedShortcut?.id ? shortcutSelectionBackgroundColor : listBackgroundColor))
                            .foregroundColor((shortcut.id == self.selection.selectedShortcut?.id ? shortcutSelectionTextColor : listTextColor))
                            .onDrag {
                                return NSItemProvider(object: shortcut)
                            }
                    }
                    .onInsert(of: [ShortcutViewModel.itemProviderType], perform: dropAction)
                }
                .environment(\.defaultMinListRowHeight, rowHeight)
            }
        }
        
    }

    private func dropAction(at index: Int, _ items: [NSItemProvider]) {
        DispatchQueue.main.async {
            for item in items {
                _ = item.loadObject(ofClass: ShortcutViewModel.self) { (droppedItem, error) in
                    if error == nil {
                        if let droppedItem = droppedItem as? ShortcutViewModel {
                            if let droppedIndex = self.selection.getShortcutIndex(id: droppedItem.id) {
                                self.selection.shortcuts?.move(fromOffsets: [droppedIndex], toOffset: index)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ShortcutList_Previews: PreviewProvider {
    static var previews: some View {
        ShortcutList(selection: Selection(master: master))
    }
}
