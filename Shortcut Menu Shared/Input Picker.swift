//
//  Input Picker.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 18/12/2024.
//  Copyright © 2024 Marc Shearer. All rights reserved.
//

import SwiftUI

protocol PickerEnum : Equatable, Hashable, CaseIterable, Equatable, Identifiable {
    static var pickerCases: [Self] {get}
    var string: String {get}
}

struct InputPicker<PickerType> : View where PickerType:PickerEnum {
    
    var title: String?
    var text: String?
    @Binding var field: PickerType
    var message: Binding<String>?
    var messageOffset: CGFloat = 0.0
    var topSpace: CGFloat = inputTopHeight
    var height: CGFloat = inputToggleDefaultHeight
    var isEnabled: Bool
    var isReadOnly: Bool = false
    var onChange: ((PickerType)->())?
    var width: CGFloat? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            if title != nil {
                InputTitle(title: title, message: message, messageOffset: messageOffset, topSpace: topSpace, isEnabled: isEnabled)
                Spacer().frame(height: 8)
            }
            HStack(spacing: 0) {
                Spacer().frame(width: 26)
                Picker("", selection: $field) {
                    ForEach(PickerType.pickerCases) { value in
                        Text("\(value.string)")
                            .contentShape(Rectangle())
                            .frame(width: width ?? 80)
                            .fixedSize()
                    }
                }
                .listRowInsets(.init())
                .pickerStyle(.segmented)
                .focusable(false)
                .font(inputFont)
                .onChange(of: field, initial: false) { (_, value) in
                    onChange?(value)
                }
                .disabled(!isEnabled || isReadOnly)
                .foregroundColor(isEnabled ? Palette.input.text : Palette.input.faintText)
                Spacer().frame(width: 24)
                Spacer()
            }
        }
        .frame(height: self.height + self.topSpace + (title == nil ? 0 : 30))
    }
}
