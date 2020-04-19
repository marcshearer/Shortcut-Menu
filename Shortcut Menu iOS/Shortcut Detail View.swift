//
//  Shortcut Detail View.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 13/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct ShortcutDetailView: View {
    
    @ObservedObject var shortcut: ShortcutViewModel
    public var title: String
    public var mode: editMode
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                
                ShortcutDetailSection(header: "Shortcut Name") {
                    textField("Enter name for shortcut", value: $shortcut.name)
                }
                .foregroundColor(.secondary)
                
                ShortcutDetailSection(header: "Shortcut value") {
                    textField("Enter value for shortcut", value: $shortcut.value)
                }
                .foregroundColor(.secondary)
                
                ShortcutDetailSection(header: "Shortcut section") {
                    Picker(selection: self.$shortcut.section, label: Text("")) {
                        ForEach(sections) { (section) in
                            Text(section.name).tag(section.name)
                        }
                        .padding(.horizontal)
                    }
                    .labelsHidden()
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                }
                
            }
            .navigationBarTitle(self.title)
            .navigationBarItems(trailing:
                Button(action: {
                    if self.mode == .create && self.shortcut.name != "" {
                        shortcuts.append(self.shortcut)
                    }
                    self.presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image("chevron.down.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.black)
                })
            )
        }
    }
    
    private func textField(_ placeholder: String, value: Binding<String>) -> some View {
        return TextField(placeholder, text: value)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .lineLimit(nil)
            .padding(.horizontal)
    }
    
}

struct ShortcutDetailSection <Content> : View where Content : View {

    var header: String
    var content: Content

    @inlinable public init(header: String, @ViewBuilder content: () -> Content) {
        self.header = header
        self.content = content()
    }

    var body : some View {
        Section(header: Text(self.header)) {
            self.content
        }
        .font(.system(size: 20, weight: .light, design: .default))
        .foregroundColor(.secondary)
        .multilineTextAlignment(.leading)
        .padding(.top, 0)
        .padding(.bottom, 0)
    }
}

struct ShortcutDetailView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        ShortcutDetailView(shortcut: shortcuts.first!, title: "Shortcut Detail", mode: .amend)
    }
}
