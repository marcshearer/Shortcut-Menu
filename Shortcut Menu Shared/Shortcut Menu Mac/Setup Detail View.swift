//
//  Shortcut Detail.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 18/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct SetupDetailView: View {
    @ObservedObject public var selection: Selection
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
                        
            if self.selection.editObject == .section && self.selection.editMode == .none {
                if let shortcut = MasterData.shared.shortcuts.first(where: {$0.nestedSection?.id == self.selection.selectedSection?.id}) {
                    // Nested section - add button to un-nest it
                    ToolbarButton("remove nest") {
                        self.selection.removeShortcut(shortcut: shortcut)
                        self.selection.selectSection(section: self.selection.editSection)
                    }
                }
                Spacer().frame(width: 10)
            }
            
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
        .frame(height: defaultRowHeight)
        .background(Palette.header.background)
        .foregroundColor(Palette.header.text)
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
        return VStack(spacing: 0) {
            
            Input(title: "Section name", field: $selection.editSection.name, placeHolder: "Must be non-blank", topSpace: 10, isEnabled: self.selection.editMode != .none)
            
            Input(title: "Stand-alone menu bar title", field: $selection.editSection.menuTitle, message: $selection.editSection.nameError, width: 100, isEnabled: self.selection.editMode != .none)
            
            Spacer().frame(maxHeight: .infinity).layoutPriority(.greatestFiniteMagnitude)
        }
    }
    
    fileprivate func shortcutForm() -> some View {
        return VStack(spacing: 0) {
            let finderVisible = (self.selection.editMode != .none && MyApp.target == .macOS)
            let hideVisible = (self.selection.editMode != .none && $selection.editShortcut.copyText.wrappedValue != "")
            
            Input(title: "Shortcut name", field: $selection.editShortcut.name, message: $selection.editShortcut.nameError, placeHolder: "Must be non-blank", topSpace: 10, isEnabled: self.selection.editMode != .none)

            OverlapButton( {
                let messageOffset: CGFloat = (finderVisible ? 20.0 : 0.0)
                Input(title: "URL to link to", field: $selection.editShortcut.url, message: $selection.editShortcut.urlError, messageOffset: messageOffset, placeHolder: "URL or text must be non-blank", height: 100, keyboardType: .URL, autoCapitalize: .none, autoCorrect: false, isEnabled: self.selection.editMode != .none && self.selection.editShortcut.canEditUrl)
            }, {
                if finderVisible {
                    if self.selection.editShortcut.canEditUrl {
                        self.finderButton()
                    } else {
                        self.clearButton()
                    }
                }
            })
            
            OverlapButton( {
                let messageOffset: CGFloat = (hideVisible ? 20.0 : 0.0)
                Input(title: "Text for clipboard", field: $selection.editShortcut.copyText, message: $selection.editShortcut.copyTextError, messageOffset: messageOffset, placeHolder: "URL or text must be non-blank", secure: $selection.editShortcut.copyPrivate.wrappedValue, height: 100, isEnabled: self.selection.editMode != .none,
                      onChange: { (value) in
                        if value == "" {
                            $selection.editShortcut.copyPrivate.wrappedValue = false
                        }
                      })
            }, {
                if hideVisible {
                    self.lockButton()
                }
            })
            
            Input(title: "Description of copied text", field: $selection.editShortcut.copyMessage, placeHolder: ($selection.editShortcut.copyPrivate.wrappedValue ? "Must be non-blank" : "Blank to show copied text"), isEnabled: self.selection.editMode != .none && self.selection.editShortcut.canEditCopyMessage)
            
            if MyApp.target == .macOS {
                Input(title: "Keyboard equivalent", field: $selection.editShortcut.keyEquivalent, width: 50, isEnabled: self.selection.editMode != .none)
            }
            
            Spacer().frame(maxHeight: .infinity).layoutPriority(.greatestFiniteMagnitude)
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
        let locked = $selection.editShortcut.copyPrivate.wrappedValue
        self.lockImage = (locked ? "lock.open.fill" : "lock.fill")
        self.lockColor = (locked ? .green : .red)
    }
    
    private func lockButton() -> some View {
        return Button(action: {
            if $selection.editShortcut.copyPrivate.wrappedValue {
                LocalAuthentication.authenticate(reason: "\(MyApp.target == .iOS ? "Passcode must be entered to " : "") make private data visible",completion: {
                    self.selection.editShortcut.copyPrivate.toggle()
                    self.formatLockButton()
                    StatusMenu.shared.bringToFront()
                }, failure: {
                    StatusMenu.shared.bringToFront()
                })
            } else {
                self.selection.editShortcut.copyPrivate.toggle()
                self.formatLockButton()
            }
        },label: {
            Image(systemName: self.lockImage)
                .font(defaultFont)
                .foregroundColor(self.lockColor)
                .frame(width: 24, height: 24)
        })
        .buttonStyle(PlainButtonStyle())
        .disabled(self.selection.editMode == .none)
    }
    
    private func clearButton() -> some View {
        
        return Button(action: {
            self.selection.editShortcut.url = ""
            self.selection.editShortcut.urlSecurityBookmark = nil
        }, label: {
                Image("xmark.circle.fill.gray")
                    .resizable()
                    .frame(width: 20, height: 20)
        })
        .buttonStyle(PlainButtonStyle())
    }
    
    private func finderButton() -> some View {
        
        return Button(action: {
            StatusMenu.shared.defineAlways(onTop: false)
            SetupDetailView.findFile { (url, data) in
                self.selection.editShortcut.url = url.absoluteString
                self.selection.editShortcut.urlSecurityBookmark = data
            }
        },label: {
            Image(systemName: "folder.fill")
                .frame(width: 24, height: 24)
                .foregroundColor(Color.blue)
        })
        .buttonStyle(PlainButtonStyle())
        .disabled(self.selection.editMode == .none)
    }
    
    static public func findFile(relativeTo: URL? = nil,completion: @escaping (URL, Data)->()) {
#if canImport(AppKit)
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
                        let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: relativeTo)
                        completion(url, data)
                    } catch {
                        // Ignore error
                        print(error.localizedDescription)
                    }
                }
            }
            StatusMenu.shared.defineAlways(onTop: true)
            StatusMenu.shared.bringToFront()
        }
#endif
    }
}

struct OverlapButton <Content1, Content2> : View where Content1 : View, Content2: View {
    var mainView: ()->Content1
    var buttonView: ()->Content2
    var topSpace: CGFloat
    
    init(@ViewBuilder _ mainView: @escaping ()->Content1, @ViewBuilder _ buttonView: @escaping ()->Content2, topSpace: CGFloat = inputTopHeight) {
        self.mainView = mainView
        self.buttonView = buttonView
        self.topSpace = topSpace
    }
    
    var body: some View {
        ZStack {
            VStack {
                mainView()
            }
            VStack {
                Spacer().frame(height: topSpace)
                HStack {
                    Spacer()
                    buttonView()
                    Spacer().frame(width: 24)
                }
                Spacer()
            }
        }
    }
}
