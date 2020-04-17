//
//  Shortcut List View.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 12/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct ShortcutListView: View {

    @Environment(\.managedObjectContext) var context
         
    @State var selectedShortcut: ShortcutViewModel?
    @State var detailTitle: String = ""
    @State var detailMode: DetailMode = .none
    @State var resequenceMode: Bool = false
            
    var body: some View {
        NavigationView {
            List {
                ForEach(shortcuts) { (shortcut) in
                    ShortcutListRow(shortcut: shortcut)
                        .onTapGesture {
                            self.selectedShortcut = shortcut
                            self.detailTitle = "Shortcut Detail"
                            self.detailMode = .amend
                    }
                }
                .onMove { (indexSet, index) in
                    self.moveRows(from: indexSet, to: index)
                }
            .onDelete(perform: removeRows)
            }
            .environment(\.editMode, .constant(self.resequenceMode ? EditMode.active : EditMode.inactive))
            .navigationBarTitle("Shortcuts", displayMode: .inline)
            .navigationBarItems(trailing:
                HStack {
                    ShortcutListNewShortcutButton(resequenceMode: $resequenceMode, selectedShortcut: $selectedShortcut, detailTitle: $detailTitle, detailMode: $detailMode)
                    ShortcutListEditModeButton(editMode: $resequenceMode)
                }
            )
                .sheet(item: self.$selectedShortcut) { (shortcut) in
                    ShortcutDetailView(shortcut: shortcut, title: self.detailTitle, mode: self.detailMode)
                        .onDisappear {
                        self.selectedShortcut = nil
                    }
            }
        }
    }
    
    func moveRows(from source: IndexSet, to destination: Int) {
        shortcuts.move(fromOffsets: source, toOffset: destination)
    }
    
    func removeRows(at offsets: IndexSet) {
        let currentEditMode = resequenceMode
        shortcuts.remove(atOffsets: offsets)
        self.resequenceMode.toggle()
        if shortcuts.isEmpty {
            self.resequenceMode = false
        } else {
            self.resequenceMode = currentEditMode
        }
    }
}

struct ShortcutListView_Previews: PreviewProvider {
    static var previews: some View {
        ShortcutListView()
    }
}

struct ShortcutListRow: View {
    
    @ObservedObject var shortcut: ShortcutViewModel
    
    var body: some View {
        HStack {
            
            Text(shortcut.name)
                .frame(width: 120, height: 20, alignment: .bottomLeading)
                .lineLimit(1)
                
            Text(shortcut.value)
            .lineLimit(2)
        
            Spacer()
            
            Text(shortcut.section)
               
            
        }
        .padding()
    }
}

struct ShortcutListNewShortcutButton: View {
    
    @Binding var resequenceMode: Bool
    @Binding var selectedShortcut: ShortcutViewModel?
    @Binding var detailTitle: String
    @Binding var detailMode: DetailMode
    
    var body: some View {
        Button(action: {
            self.selectedShortcut = ShortcutViewModel(id: UUID(), name: "", value: "", section: "", sequence: shortcuts.count)
            self.detailTitle = "New Shortcut"
            self.detailMode = .create
        },
               label: {
                Image("plus.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    .opacity(resequenceMode ? 0.2 : 1.0)
        })
            .disabled(self.resequenceMode)
    }
}

struct ShortcutListEditModeButton: View {
    
    @Binding var editMode: Bool
        
    var body: some View {
        Button(action: {
            self.editMode = !self.editMode
        },
               label: {
                Image((editMode ? "xmark.circle.fill" : "arrow.up.arrow.down.circle.fill"))
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .opacity(shortcuts.isEmpty ? 0.2 : 1.0)
        })
            .disabled(shortcuts.isEmpty)
    }
}
