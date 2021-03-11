//
//  Sections.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 08/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct ShortcutListView: View {
    @ObservedObject var displayState: DisplayState
    @State var data = MasterData.shared
    
    var body: some View {
        VStack {
            if displayState.selectedSection != nil {
                sectionView(section: displayState.selectedSection!)
            }
            sectionView(section: "")
            Spacer()
        }
    }
    
    private func sectionView(section: String, inset: CGFloat = 0) -> some View {
        let shortcuts = data.shortcuts.filter({$0.section?.name == section})
        return VStack {
            Tile(dynamicText: {section == "" ? "Default Shortcuts" : displayState.shortcutsTitle}, color: Palette.header, rounded: true, insets: EdgeInsets(top: 10, leading: 10, bottom: 2, trailing: 10))
            ForEach(shortcuts) { (shortcut) in
                if shortcut.type == .section && shortcut.nestedSection != nil {
                    // sectionView(section: shortcut.nestedSection!.name, inset: inset + 30)
                } else {
                    HStack {
                        Spacer().frame(width: 30)
                        Tile(text: shortcut.name, color: Palette.background, selected: { displayState.selectedShortcut == shortcut.name }, nested: shortcut.nestedSection != nil, rounded: true, insets: EdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 10)) {
                            
                            displayState.selectedShortcut = shortcut.name
                            var message = ""
                            if shortcut.url != "" {
                                message = "Linking to \(shortcut.name)...\n\n"
                            }
                            Actions.shortcut(name: shortcut.name) { (copyMessage) in
                                if let copyMessage = copyMessage {
                                    message += copyMessage
                                }
                                MessageBox.shared.show(message, closeButton: false, hideAfter: 3)
                                Utility.executeAfter(delay: 3) {
                                    displayState.selectedShortcut = nil
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

class DisplayState: ObservableObject {
    
    @Published var selectedSection: String?
    @Published var selectedShortcut: String?
    var shortcutsTitle: String { "\(selectedSection ?? "Default") Shortcuts" }
    @Published var nestedSection: String?
    
    init() {
        self.selectedSection = UserDefault.currentSection.string
    }
}
