//
//  Sections.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 08/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct ShortcutListView: View {
    @ObservedObject public var selection: Selection
    
    var body: some View {
        VStack {
            if let currentSection = selection.selectedSection {
                Tile(text: currentSection.name, color: Palette.header)
                ForEach(selection.shortcuts) { (shortcut) in
                    Tile(text: shortcut.name, color: Palette.background, selected: { selection.selectedShortcut?.id == shortcut.id }, nested: shortcut.nestedSection != nil) {
                        
                        selection.selectShortcut(shortcut: shortcut)
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
                                selection.deselectShortcut()
                            }
                        }
                    }
                }
                Spacer()
            }
        }
    }
}
