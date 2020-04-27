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
    @ObservedObject public var editSection: SectionViewModel     // Seem to have to pass these in separately to get synch to work
    @ObservedObject public var editShortcut: ShortcutViewModel   // Seem to have to pass these in separately to get synch to work
    @State var lockImage: String = ""
    @State var lockColor: Color = .red

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
            
            Text(self.detailTitle() )
                .font(defaultFont)
            
            Spacer()
                        
            if self.selection.editObject != .none && self.selection.editMode == .none {
                ToolbarButton("pencil.circle.fill") {
                    self.selection.editMode = .amend
                    self.formatLockButton()
                }
            }
            
            if self.selection.editObject != .none && self.selection.editMode != .none {
                
                if self.canSave() {
                    ToolbarButton("checkmark.circle.fill") {
                        // Update
                        if self.selection.editObject == .section {
                            self.selection.updateSection(section: self.selection.editSection)
                        } else if self.selection.editObject == . shortcut {
                            self.selection.updateShortcut(shortcut: self.editShortcut)
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
        } else if self.selection.editObject == .shortcut && self.editShortcut.canSave {
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

            self.message(text: self.selection.editSection.nameError)
        }
    }
    
    fileprivate func shortcutForm() -> some View {
        return Form {
            DetailViewSection(header: "Shortcut name") {
                textField("Must be non-blank", value: $editShortcut.name)
            }
            .foregroundColor(.secondary)

            self.message(text: self.editShortcut.nameError)
            
            DetailViewSection(header: "URL to link to", content: {
                HStack(alignment: .top) {
                    VStack {
                        ZStack(alignment: .trailing) {
                            textField("URL or text must be non-blank", value: $editShortcut.url, forceDisabled: !self.editShortcut.canEditUrl)
                            
                            if !self.editShortcut.canEditUrl && self.selection.editMode != .none {
                                HStack(alignment: .center) {
                                    Button(action: {
                                        self.editShortcut.url = ""
                                        self.editShortcut.urlSecurityBookmark = nil
                                        self.selection.objectWillChange.send()
                                    }, label: {
                                        Image("xmark.circle.fill.gray")
                                            .padding()
                                            .frame(width: 20, height: 20)
                                            .background(Color.white)
                                            .scaledToFit()
                                    })
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Spacer()
                                        .frame(width: 20)
                                }
                            }
                        }
                        self.message(text: self.editShortcut.urlError)
                    }
                    
                    if self.selection.editMode != .none && self.editShortcut.canEditUrl {
                        Spacer()
                        self.finderButton()
                        Spacer()
                    }
                }
            })
                .foregroundColor(.secondary)
            
            DetailViewSection(header: "Text to copy to clipboard", content: {
                HStack {
                    VStack {
                        if self.editShortcut.copyPrivate {
                            secureField("URL or text must be non-blank", value: $editShortcut.copyText)
                        } else {
                            textField("URL or text must be non-blank", value: $editShortcut.copyText)
                        }
                        
                        self.message(text: self.editShortcut.copyTextError)
                    }
                    
                    if self.selection.editMode != .none && self.editShortcut.copyText != "" {
                        Spacer()
                        self.lockButton()
                        Spacer()
                    }
                }
            })
            .foregroundColor(.secondary)
            
            if self.editShortcut.canEditCopyMessage {
                DetailViewSection(header: "Message to show instead of copied text", content: {
                    VStack {
                        textField("Blank to show copied text", value: $editShortcut.copyMessage)
                        
                         self.message(text: self.editShortcut.copyMessageError)
                    }
                })
                .foregroundColor(.secondary)
            }
            
        }
    }
    
    private func detailTitle() -> String {
        
        switch self.selection.editObject {
        case .section:
            return "\(self.selection.editMode == .create ? "New " : "")Section Details"
        case .shortcut:
            return "Shortcut Details"
        case .none:
            return "Nothing Selected"
        }
    }
    
    private func message(text: String) -> some View {
        return HStack {
                    Spacer()
                    Text(text)
                        .font(messageFont)
                        .foregroundColor(.red)
                    Spacer()
                        .frame(width: 20)
                }
    }
    
    private func formatLockButton() {
        let locked = editShortcut.copyPrivate
        self.lockImage = (locked ? "unlock" : "lock")
        self.lockColor = (locked ? .green : .red)
    }
    
    private func lockButton() -> some View {
        return Button(action: {
            if self.editShortcut.copyPrivate {
                LocalAuthentication.authenticate(reason: "show private data",completion: {
                    self.editShortcut.copyPrivate.toggle()
                    self.formatLockButton()
                    StatusMenu.shared.bringToFront()
                }, failure: {
                    StatusMenu.shared.bringToFront()
                })
            } else {
                self.editShortcut.copyPrivate.toggle()
                self.formatLockButton()
            }
        },label: {
            Image(self.lockImage)
                .padding()
                .frame(width: 30, height: 30)
                .background(self.lockColor)
                .clipShape(Circle())
                .scaledToFit()
        })
        .buttonStyle(PlainButtonStyle())
        .disabled(self.selection.editMode == .none)
    }
    
    private func finderButton() -> some View {
        
        return Button(action: {
            StatusMenu.shared.defineAlways(onTop: false)
            let openPanel = NSOpenPanel()
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseDirectories = false
            openPanel.canCreateDirectories = false
            openPanel.canChooseFiles = true
            openPanel.prompt = "Select target"
            openPanel.level = .floating
            openPanel.begin { result in
                if result == .OK {
                    if !openPanel.urls.isEmpty {
                        let url = openPanel.urls[0]
                        do {
                            let data = try url.bookmarkData(options: .securityScopeAllowOnlyReadAccess, includingResourceValuesForKeys: nil, relativeTo: nil)
                            self.selection.objectWillChange.send()
                            self.editShortcut.url = url.absoluteString
                            self.editShortcut.urlSecurityBookmark = data
                        } catch {
                            // Ignore error
                        }
                    }
                }
                StatusMenu.shared.defineAlways(onTop: true)
                StatusMenu.shared.bringToFront()
            }
        },label: {
            Image("folder")
                .padding()
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .clipShape(Circle())
                .scaledToFit()
        })
        .buttonStyle(PlainButtonStyle())
        .disabled(self.selection.editMode == .none)
    }
    
    private func textField(_ placeholder: String, value: Binding<String>, forceDisabled: Bool = false) -> some View {
        return TextField(placeholder, text: value)
            .disabled(forceDisabled || self.selection.editMode == .none)
            .opacity((forceDisabled || self.selection.editMode == .none ? 0.5 : 1.0))
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .lineLimit(nil)
            .padding(.horizontal)
    }
    
    private func secureField(_ placeholder: String, value: Binding<String>) -> some View {
        return SecureField(placeholder, text: value)
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
    }
}
