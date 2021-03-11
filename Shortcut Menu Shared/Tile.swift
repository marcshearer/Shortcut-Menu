//
//  Tile.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 10/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct Tile: View {
    @State var text: String?
    @State var dynamicText: (()->(String))?
    @State var color: PaletteColor = Palette.unselectedList
    @State var selectedColor: PaletteColor = Palette.selectedList
    @State var selected: (()->Bool)?
    @State var disabled: Bool = false
    @State var nested: Bool = false
    @State var rounded: Bool = false
    @State var insets = EdgeInsets()
    @State var tapAction: (()->())?

    var body: some View {
        let color = ((selected?() ?? false) ? self.selectedColor : self.color)
        VStack {
            Spacer()
            HStack {
                if nested {
                    Spacer().frame(width: 16)
                    Image(systemName: "folder")
                        .foregroundColor(color.faintText)
                        .font(defaultFont)
                    Spacer().frame(width: 10)
                }
                Text(text ?? dynamicText?() ?? "")
                    .padding([.leading, .trailing], 16)
                    .font(defaultFont)
                    .foregroundColor(nested || disabled ? color.faintText : color.text)
                Spacer()
            }
            Spacer()
        }
        .frame(height: defaultRowHeight, alignment: .leading)
        .background(color.background)
        .cornerRadius(rounded ? 10 : 0)
        .padding(insets)
        .onTapGesture {
            Utility.mainThread {
                tapAction?()
            }
        }
    }
}
