//
//  CustomViews.swift
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
        Button(action: action, label: {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30.0, height: 30.0, alignment: .center)
                .foregroundColor(.white)
        })
        .background(Color.clear)
        .foregroundColor(Color.clear)
        .buttonStyle(PlainButtonStyle())
    }
}
