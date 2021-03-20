//
//  Tile.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 10/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct Tile: View {
    @State var leadingImageName: (()->(String?))?
    @State var leadingAction: (()->())? = nil
    @State var text: String?
    @State var dynamicText: (()->(String))?
    @State var trailingImageName: (()->(String?))?
    @State var color: PaletteColor = Palette.unselectedList
    @State var selectedColor: PaletteColor = Palette.selectedList
    @State var selected: (()->Bool)?
    @State var disabled: Bool = false
    @State var rounded: Bool = false
    @State var insets = EdgeInsets()
    @State var trailingContent: (()->AnyView)?
    @State var tapAction: (()->())?

    var body: some View {
        let color = ((selected?() ?? false) ? self.selectedColor : self.color)
        let textColor = (disabled ? color.faintText : color.text)
        VStack {
            Spacer()
            HStack {
                if let leadingImageName = leadingImageName?() {
                    HStack {
                        Spacer().frame(width: 16)
                        Image(systemName: leadingImageName)
                            .foregroundColor(textColor)
                            .font(defaultFont)
                        Spacer().frame(width: 10)
                    }
                    .onTapGesture {
                        leadingAction?()
                    }
                }
                Text(text ?? dynamicText?() ?? "")
                    .padding([.leading, .trailing], 16)
                    .font(defaultFont)
                    .minimumScaleFactor(0.75)
                    .foregroundColor(textColor)
                Spacer()
                if let trailingImageName = trailingImageName?() {
                    Spacer().frame(width: 2)
                    Image(systemName: trailingImageName)
                        .foregroundColor(textColor)
                        .font(defaultFont)
                    Spacer().frame(width: 10)
                }
                if let rightContent = trailingContent {
                    rightContent()
                    Spacer().frame(width: 32)
                }
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
