//
//  Shortcut Detail.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 18/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct DetailView: View {
    
    @ObservedObject public var selection: Selection

    var body: some View {
        
        VStack(spacing: 0) {
            
            titleBar()
                
            Spacer()
                .frame(height: 10.0)
            
            HStack {
                Spacer()
                    .frame(width: 10.0)
                
                if self.selection.editObject == .shortcut {
                    shortcutForm()
                } else if self.selection.editObject ==  .section {
                    sectionForm()
                }
            }
            
            Spacer()
        }
        .background(Color.white)
    }
    
    fileprivate func titleBar() -> some View {
        
        HStack(spacing: 0.0) {
            Spacer()
                .frame(width: 10.0)
            
            Text(self.title() )
                .font(defaultFont)
            
            Spacer()
                        
            if self.selection.editObject != .none && self.selection.editMode == .none {
                ToolbarButton("pencil.circle.fill") {
                    self.selection.editMode = .amend
                }
            }
            
            if self.selection.editObject != .none && self.selection.editMode != .none {
                
                if self.canSave() {
                    ToolbarButton("checkmark.circle.fill") {
                        // Update
                        if self.selection.editObject == .section {
                            self.selection.updateSection(section: self.selection.editSection)
                        } else if self.selection.editObject == . shortcut {
                            self.selection.updateShortcut(shortcut: self.selection.editShortcut)
                        }
                        self.selection.editMode = .none
                    }
                }
                
                ToolbarButton("xmark.circle.fill") {
                    // Revert
                    if self.selection.editMode == .create {
                        self.selection.editObject = .none
                    } else {
                        if self.selection.editObject == .section {
                            self.selection.selectSection(section: self.selection.selectedSection!)
                        } else if self.selection.editObject == . shortcut {
                            self.selection.selectShortcut(shortcut: self.selection.selectedShortcut!)
                        }
                    }
                    self.selection.editMode = .none
                }
            }
            
            Spacer()
                .frame(width: 5.0)
        }
        .frame(width: detailWidth, height: rowHeight)
        .background(titleBackgroundColor)
        .foregroundColor(titleTextColor)
    }
    
    fileprivate func canSave() -> Bool {
        var result = false
        
        if self.selection.editObject == .section && self.selection.editSection.canSave {
            result = true
        } else if self.selection.editObject == .shortcut && self.selection.editShortcut.canSave {
            result = true
        }
        
        return result
    }
    
    fileprivate func sectionForm() -> some View {
        return Form {
            DetailViewSection(header: "Section name") {
                textField("Must be non-blank", value: $selection.editSection.name)
            }
            .foregroundColor(.secondary)
        }
    }
    
    fileprivate func shortcutForm() -> some View {
        return Form {
            DetailViewSection(header: "Shortcut name") {
                textField("Must be non-blank", value: $selection.editShortcut.name)
            }
            .foregroundColor(.secondary)
            
            DetailViewSection(header: "Shortcut value", content: {
                textField("Must be non-blank", value: $selection.editShortcut.value)
            })
            .foregroundColor(.secondary)
        }
    }
    
    private func title() -> String {
        
        switch self.selection.editObject {
        case .section:
            return "\(self.selection.editMode == .create ? "New " : "")Section Details"
        case .shortcut:
            return "Shortcut Details"
        case .none:
            return "Nothing Selected"
        }
        
    }
    
    private func textField(_ placeholder: String, value: Binding<String>) -> some View {
        return TextField(placeholder, text: value)
            .disabled(self.selection.editMode == .none)
            .opacity((self.selection.editMode == .none ? 0.5 : 1.0))
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .lineLimit(nil)
            .padding(.horizontal)
    }
}

struct DetailViewSection <Content> : View where Content : View {

    var header: String
    var content: Content

    public init(header: String, @ViewBuilder content: () -> Content) {
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
