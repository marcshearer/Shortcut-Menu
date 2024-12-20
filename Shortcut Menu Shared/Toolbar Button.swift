//
//  Toolbar Button.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 18/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct ToolbarButton: View {
    
    public var imageName: String
    public var action: ()->()
    
    init(_ imageName: String, action: @escaping ()->()) {
        self.imageName = imageName
        self.action = action
    }
    
    var body: some View {
        let size: CGFloat = (MyApp.target == .iOS ? 30.0 : 25.0)
        Button(action: action, label: {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size, alignment: .center)
                .foregroundColor(Palette.header.text)
        })
        .background(Color.clear)
        .foregroundColor(Color.clear)
        .buttonStyle(PlainButtonStyle())
        #if os(macOS)
            .focusEffectDisabled()
        #endif
    }
}
