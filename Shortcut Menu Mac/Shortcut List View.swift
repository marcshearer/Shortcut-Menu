//
//  Sections.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 08/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct ShortcutListView: View {
    @ObservedObject var data = MasterData.shared
    
    @Binding var currentSection: String
    
    var body: some View {
        VStack {
            if currentSection != defaultSectionMenuName {
                Tile(text: currentSection, color: Palette.header)
                let shortcuts = data.shortcuts.filter({$0.section?.name == currentSection})
                ForEach(shortcuts) { (shortcut) in
                    Tile(text: shortcut.name, color: Palette.background)
                }
            }
            Spacer()
        }
    }
}

struct Tile: View {
    @State var text: String
    @State var color: PaletteColor
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer().frame(width: 20)
                Text(text).font(defaultFont).foregroundColor(color.text)
                Spacer()
            }
            Spacer()
        }
        .background(color.background)
        .frame(height: defaultRowHeight)
    }
}
