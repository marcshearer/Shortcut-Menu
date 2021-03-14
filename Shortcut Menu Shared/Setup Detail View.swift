//
//  Shortcut Detail.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 18/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI
import Carbon.HIToolbox

struct SetupDetailView: View {
    @ObservedObject public var selection: Selection
    @State private var lockImage: String = ""
    @State private var lockColor: Color = .red
    @State private var isSettingShortcutKey: Bool = false
    private var isEnabled: Bool {
        selection.editAction != .none && !isSettingShortcutKey
    }

    init(selection: Selection) {
        self.selection = selection
    }
    
    var body: some View {
        
        ZStack {
            
            VStack(spacing: 0) {
                
                titleBar()
                
                Spacer()
                    .frame(height: 10.0)
                
                HStack {
                    Spacer()
                        .frame(width: 10.0)
                    
                    if selection.editObject == .shortcut {
                        shortcutForm()
                    } else if selection.editObject ==  .section {
                        sectionForm()
                    }
                }
                
                Spacer()
            }
            .background(Color.white)
            
        }
    }
    
    fileprivate func titleBar() -> some View {
        
        HStack(spacing: 0.0) {
            Spacer()
                .frame(width: 10.0)
            
            Text(self.detailTitle() )
                .font(defaultFont)
            
            Spacer()
                        
            if selection.editObject == .section && !isEnabled {
                if let shortcut = MasterData.shared.shortcuts.first(where: {$0.nestedSection?.id == selection.selectedSection?.id}) {
                    // Nested section - add button to un-nest it
                    ToolbarButton("remove nest") {
                        selection.removeShortcut(shortcut: shortcut)
                        selection.selectSection(section: selection.editSection)
                    }
                }
                Spacer().frame(width: 10)
            }
            
            if selection.editObject != .none && !isEnabled && !isSettingShortcutKey {
                ToolbarButton("pencil.circle.fill") {
                    selection.editAction = .amend
                    self.formatLockButton()
                }
            }
            
            if selection.editObject != .none && (isEnabled || isSettingShortcutKey) {
                
                if self.canSave() {
                    ToolbarButton("checkmark.circle.fill") {
                        // Update
                        if selection.editObject == .section {
                            selection.updateSection(section: selection.editSection)
                        } else if selection.editObject == . shortcut {
                            selection.updateShortcut(shortcut: selection.editShortcut)
                        }
                        selection.editAction = .none
#if canImport(AppKit)
                        isSettingShortcutKey = false
                        ShortcutKeyMonitor.shared.stopDefine()
                        StatusMenu.shared.updateShortcutKeys()
#endif
                    }
                }
                
                ToolbarButton("xmark.circle.fill") {
                    // Revert
                    if selection.editAction == .create {
                        selection.editObject = .none
                    } else {
                        if selection.editObject == .section {
                            selection.selectSection(section: selection.selectedSection!)
                        } else if selection.editObject == . shortcut {
                            selection.selectShortcut(shortcut: selection.selectedShortcut!)
                        }
                    }
                    isSettingShortcutKey = false
                    ShortcutKeyMonitor.shared.stopDefine()
                    selection.editAction = .none
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
        
        if selection.editObject == .section && selection.editSection.canSave {
            result = true
        } else if selection.editObject == .shortcut && selection.editShortcut.canSave {
            result = true
        }
        
        return result
    }
    
    fileprivate func sectionForm() -> some View {
        return VStack(spacing: 0) {
            
            if !selection.editSection.isDefault {
                Input(title: "Section name", field: $selection.editSection.name, message: $selection.editSection.nameError, placeHolder: "Must be non-blank", topSpace: 10, isEnabled: isEnabled)
            }
            
            Input(title: "Stand-alone menu bar title", field: $selection.editSection.menuTitle, width: 100, isEnabled: isEnabled)
            
            if MyApp.target == .macOS {
                self.shortcutKey(key: $selection.editSection.keyEquivalent, notify: sectionKeyNotify, disabled: {!selection.editSection.canEditKeyEquivalent})
            }

            Spacer().frame(maxHeight: .infinity).layoutPriority(.greatestFiniteMagnitude)
            
        }
    }
    
    fileprivate func shortcutForm() -> some View {
        return VStack(spacing: 0) {
            let finderVisible = (isEnabled && MyApp.target == .macOS)
            let hideVisible = (isEnabled && $selection.editShortcut.copyText.wrappedValue != "")
            
            Input(title: "Shortcut name", field: $selection.editShortcut.name, message: $selection.editShortcut.nameError, placeHolder: "Must be non-blank", topSpace: 10, isEnabled: isEnabled)

            OverlapButton( {
                let messageOffset: CGFloat = (finderVisible ? 20.0 : 0.0)
                Input(title: "URL to link to", field: $selection.editShortcut.url, message: $selection.editShortcut.urlError, messageOffset: messageOffset, placeHolder: "URL or text must be non-blank", height: 100, keyboardType: .URL, autoCapitalize: .none, autoCorrect: false, isEnabled: isEnabled && selection.editShortcut.canEditUrl)
            }, {
                if finderVisible {
                    if selection.editShortcut.canEditUrl {
                        self.finderButton()
                    } else {
                        self.clearButton()
                    }
                }
            })
            
            OverlapButton( {
                let messageOffset: CGFloat = (hideVisible ? 20.0 : 0.0)
                Input(title: "Text for clipboard", field: $selection.editShortcut.copyText, message: $selection.editShortcut.copyTextError, messageOffset: messageOffset, placeHolder: "URL or text must be non-blank", secure: $selection.editShortcut.copyPrivate.wrappedValue, height: 100, isEnabled: isEnabled,
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
            
            Input(title: "Description of copied text", field: $selection.editShortcut.copyMessage, placeHolder: ($selection.editShortcut.copyPrivate.wrappedValue ? "Must be non-blank" : "Blank to show copied text"), isEnabled: isEnabled && selection.editShortcut.canEditCopyMessage)
            
            if MyApp.target == .macOS {
                self.shortcutKey(key: $selection.editShortcut.keyEquivalent, notify: shortcutKeyNotify, disabled: {false})
            }
            
            Spacer().frame(maxHeight: .infinity).layoutPriority(.greatestFiniteMagnitude)
        }
    }
    
    private func detailTitle() -> String {
        
        switch selection.editObject {
        case .section:
            return "\(selection.editAction == .create ? "New " : "")Section Details"
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
                    selection.editShortcut.copyPrivate.toggle()
                    self.formatLockButton()
                    StatusMenu.shared.bringToFront()
                }, failure: {
                    StatusMenu.shared.bringToFront()
                })
            } else {
                selection.editShortcut.copyPrivate.toggle()
                self.formatLockButton()
            }
        },label: {
            Image(systemName: self.lockImage)
                .font(defaultFont)
                .foregroundColor(self.lockColor)
                .frame(width: 24, height: 24)
        })
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
    }
    
    private func clearButton() -> some View {
        
        return Button(action: {
            selection.editShortcut.url = ""
            selection.editShortcut.urlSecurityBookmark = nil
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
                selection.editShortcut.url = url.absoluteString
                selection.editShortcut.urlSecurityBookmark = data
            }
        },label: {
            Image(systemName: "folder.fill")
                .frame(width: 24, height: 24)
                .foregroundColor(Color.blue)
        })
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
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
    
    private func shortcutKey(key: Binding<String>, notify: @escaping (String)->(), disabled: ()->(Bool)) -> some View {
        VStack {
            let enable = (isEnabled || isSettingShortcutKey) && !disabled()
            Spacer().frame(height: inputTopHeight)
            InputTitle(title: "Shortcut key", isEnabled: enable)
            Spacer().frame(height: 8)
            HStack {
                Spacer().frame(width: 32)
                HStack {
                    Spacer().frame(width: 10)
                    Text(key.wrappedValue)
                        
                        .font(inputFont)
                        .foregroundColor(enable ? Palette.input.text : Palette.input.faintText)
                        .font(defaultFont)
                    Spacer()
                }
                .frame(width: 100, height: inputDefaultHeight)
                .background(Palette.input.background)
                .cornerRadius(10)
                if enable {
                    Spacer().frame(width: 16)
                    Button(action: {
                        isSettingShortcutKey.toggle()
                        if isSettingShortcutKey {
                            ShortcutKeyMonitor.shared.startDefine(notify: notify)
                        } else {
                            ShortcutKeyMonitor.shared.stopDefine()
                        }
                    }) {
                        Text(isSettingShortcutKey ? "Cancel" : (key.wrappedValue == "" ? "Add" : "Change"))
                            .frame(width: 80, height: inputDefaultHeight)
                            .background(Palette.enabledButton.background)
                            .foregroundColor(Palette.enabledButton.text)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!enable)
                }
                Spacer()
            }
                Spacer().frame(height: 8)
                HStack {
                    Spacer().frame(width: 32)
                    Text(isSettingShortcutKey ? "Press key to set or Backspace to clear" : "")
                        .font(messageFont)
                        .foregroundColor(Palette.background.themeText)
                        .frame(height: 10)
                    Spacer()
            }
            Spacer()
        }
        .frame(height: inputDefaultHeight + inputTopHeight + 40)
    }
    
    private func shortcutKeyNotify(_ key: String) {
        selection.editShortcut.keyEquivalent = key
        ShortcutKeyMonitor.shared.stopDefine()
        isSettingShortcutKey = false
        selection.objectWillChange.send()
    }
    
    private func sectionKeyNotify(_ key: String) {
        selection.editSection.keyEquivalent = key
        ShortcutKeyMonitor.shared.stopDefine()
        isSettingShortcutKey = false
        selection.objectWillChange.send()
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