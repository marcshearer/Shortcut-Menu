//  Input Float.swift
//  BridgeScore
//
//  Created by Marc Shearer on 07/02/2022.
//

import SwiftUI

struct InputFloat : View {
    
    var title: String?
    @Binding var field: Float
    var message: Binding<String>?
    var topSpace: CGFloat = 0
    var leadingSpace: CGFloat = 0
    var height: CGFloat = inputDefaultHeight
    var width: CGFloat?
    var places: Int = 2
    var onChange: ((Float?)->())?
    
    @State private var wrappedText = ""
    var text: Binding<String> {
        Binding {
            wrappedText
        } set: { (newValue) in
            wrappedText = newValue
        }
    }
    
    
    var body: some View {
        
        VStack(spacing: 0) {
            if title != nil {
                HStack {
                    InputTitle(title: title, message: message, topSpace: topSpace)
                }
                Spacer().frame(height: 8)
            }
            GeometryReader { (geometry) in
                HStack {
                    Spacer().frame(width: 32)
                    HStack {
                        TextField("", text: text, onEditingChanged: {(editing) in
                            text.wrappedValue = Float(text.wrappedValue)?.toString(places: places) ?? ""
                            field = Utility.round(Float(text.wrappedValue) ?? 0, places: places)
                        })
                        .onSubmit {
                            text.wrappedValue = Float(text.wrappedValue)?.toString(places: places) ?? ""
                            field = Utility.round(Float(text.wrappedValue) ?? 0, places: places)
                        }
                        .onChange(of: text.wrappedValue, initial: false) { (_, newValue) in
                            let filtered = newValue.filter { "0123456789 -,.".contains($0) }
                            let oldField = field
                            if filtered != newValue {
                                text.wrappedValue = filtered
                            }
                            field = Utility.round(Float(text.wrappedValue) ?? 0, places: places)
                            if oldField != field {
                                onChange?(field)
                            }
                        }
                        .lineLimit(1)
                        .padding(EdgeInsets(top: 1, leading: 10, bottom: 1, trailing: 10))
                        .disableAutocorrection(false)
                        .textFieldStyle(.plain)
                    }
                    .frame(width: width ?? geometry.size.width - 56, height: height)
                    .background(Palette.input.background)
                    .cornerRadius(8)
                }
                .font(inputFont)
                .onChange(of: field, initial: false) { (_, field) in
                    let newValue = field.toString(places: places)
                    if newValue != wrappedText {
                        wrappedText = newValue
                    }
                }
                .onAppear {
                    text.wrappedValue = field.toString(places: places)
                }
            }
        }
        .frame(height: self.height + self.topSpace + (title == nil ? 0 : 30))
    }
}
