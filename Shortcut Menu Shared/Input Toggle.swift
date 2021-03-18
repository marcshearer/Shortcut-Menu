//
//  Input Toggle.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 15/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct InputToggle : View {
    
    var title: String?
    var text: String?
    @Binding var field: Bool
    var message: Binding<String>?
    var messageOffset: CGFloat = 0.0
    var topSpace: CGFloat = inputTopHeight
    var height: CGFloat = inputToggleDefaultHeight
    var isEnabled: Bool
    var isReadOnly: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            if title != nil {
                InputTitle(title: title, message: message, messageOffset: messageOffset, topSpace: topSpace, isEnabled: isEnabled)
                Spacer().frame(height: 8)
            }
            GeometryReader { geometry in
                HStack {
                    Spacer().frame(width: 32)
                    Toggle(isOn: $field) {
                        Text(text ?? "")
                    }
                    .disabled(!isEnabled || isReadOnly)
                    .foregroundColor(isEnabled ? Palette.input.text : Palette.input.faintText)
                    Spacer()
                    Spacer().frame(width: 16)
                }
            }
        }
        .frame(height: self.height + self.topSpace + (title == nil ? 0 : 30))
    }
}
