//
//  Shortcut Detail.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 18/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct SetupDetailView: View {
    @ObservedObject var selection: Selection
    @Binding public var panel: SetupPanel
    @State private var lockImage: String = ""
    @State private var lockColor: Color = .red
    @State private var isSettingShortcutKey: Bool = false
    @State private var refresh = true
    
    private var isEnabled: Bool {
        selection.editAction != .none && !isSettingShortcutKey
    }
    
    var body: some View {
        
        ZStack {
            
            VStack(spacing: 0) {
                
                // Just to trigger view refresh
                if refresh { EmptyView() }
                
                titleBar()
                
                ScrollView {
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
            }
            .onAppear() {
                self.formatLockButton()
            }
        }
    }
    
    fileprivate func titleBar() -> some View {
        
        HStack {
            Spacer().frame(width: 16.0)
            
            if panel == .detail && selection.editAction == .none {
                Image(systemName: "arrow.turn.up.left")
                    .font(.title)
                    .onTapGesture {
                        panel = .shortcuts
                    }
            }
            
            Text(self.detailTitle() )
                .font(defaultFont)
            
            Spacer()
            
            if selection.editObject != .none && !isEnabled && !isSettingShortcutKey {
                if panel != .all && selection.editObject == .shortcut {
                    ToolbarButton("folder.circle.fill") {
                        self.changeSection()
                    }
                }
                ToolbarButton("pencil.circle.fill") {
                    selection.editAction = .amend
                    self.formatLockButton()
                }
            }
            
            if selection.editObject != .none && (isEnabled || isSettingShortcutKey) {
                
                if self.canSave() {
                    if panel != .all && selection.editAction != .create{
                        // Need a delete option since not available in lists
                        ToolbarButton("trash.circle.fill") {
                            selection.editAction = .none
                            if selection.editObject == .section {
                                selection.removeSection(section: selection.editSection)
                                selection.deselectSection()
                                panel = .sections
                            } else if selection.editObject == .shortcut {
                                selection.removeShortcut(shortcut: selection.editShortcut)
                                selection.deselectShortcut()
                                panel = .shortcuts
                            }
                        }
                    }
                    
                    ToolbarButton("checkmark.circle.fill") {
                        // Update
                        selection.editAction = .none
                        if selection.editObject == .section {
                            selection.updateSection(section: selection.editSection)
                        } else if selection.editObject == . shortcut {
                            selection.updateShortcut(shortcut: selection.editShortcut)
                        }
                        selection.objectWillChange.send()
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
                        if panel != .all {
                            if selection.editObject == .shortcut {
                                panel = .shortcuts
                            } else {
                                panel = .sections
                            }
                        }
                        selection.editObject = .none
                    } else {
                        if selection.editObject == .section {
                            selection.selectSection(section: selection.selectedSection!)
                        } else if selection.editObject == . shortcut {
                            selection.selectShortcut(shortcut: selection.selectedShortcut!)
                        }
                    }
                    isSettingShortcutKey = false
#if canImport(AppKit)
                    ShortcutKeyMonitor.shared.stopDefine()
#endif
                    selection.editAction = .none
                }
            }
            
            Spacer().frame(width: 10.0)
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
                
                if MasterData.shared.isNested(selection.editSection) {
                    InputToggle(title: "Show Inline", text: "Show contents of section inline", field: $selection.editSection.inline, isEnabled: isEnabled)
                }
                
                if MyApp.target == .macOS {
                    
                    Input(title: "Stand-alone menu bar title", field: $selection.editSection.menuTitle, width: 100, isEnabled: isEnabled) { (newValue) in
                        if newValue == "" {
                            selection.editSection.temporary = false
                            selection.editSection.quickDrop = false
                        }
                    }
                    
                    self.shortcutKey(key: $selection.editSection.keyEquivalent, notify: sectionKeyNotify, disabled: {!selection.editSection.canEditKeyEquivalent})
                }
            }
            
            InputToggle(title: "Section type", text: "Temporary shortcuts", field: $selection.editSection.temporary, isEnabled: isEnabled && selection.editSection.menuTitle != "")
            
            InputToggle(text: "Allow quick drop", field: $selection.editSection.quickDrop, isEnabled: isEnabled && selection.editSection.menuTitle != "")
            
            if Settings.shared.shareShortcuts.value {
                
                InputToggle(title: "Share With Other Devices", text: "Shared with other devices", field: $selection.editSection.shared, isEnabled: isEnabled && selection.editSection.canShare)
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
                Input(title: "URL to link to", field: $selection.editShortcut.url, message: $selection.editShortcut.urlError, messageOffset: messageOffset, placeHolder: "URL or text must be non-blank", height: 80, keyboardType: .URL, autoCapitalize: .none, autoCorrect: false, isEnabled: isEnabled && $selection.editShortcut.canEditUrl.wrappedValue)
            }, {
                if finderVisible {
                    if $selection.editShortcut.canEditUrl.wrappedValue {
                        self.finderButton()
                    } else {
                        self.clearButton()
                    }
                }
            })
            
            OverlapButton( {
                let messageOffset: CGFloat = (hideVisible ? 20.0 : 0.0)
                Input(title: "Text for clipboard", field: $selection.editShortcut.copyText, message: $selection.editShortcut.copyTextError, messageOffset: messageOffset, placeHolder: "URL or text must be non-blank", secure: $selection.editShortcut.copyPrivate.wrappedValue, height: 80, isEnabled: isEnabled,
                      onChange: { (value) in
                        if value == "" {
                            selection.editShortcut.copyPrivate = false
                            refresh.toggle()
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
            
            if Settings.shared.shareShortcuts.value {
                
                InputToggle(title: "Share With Other Devices", text: "Shared with other devices", field: $selection.editShortcut.shared, isEnabled: isEnabled && selection.editShortcut.canShare && (selection.editShortcut.section?.isShared ?? false))
                
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
    
    
    private func changeSection() {
        
        let options = MasterData.shared.getSections(excludeSections: [selection.selectedSection!.name], excludeDefault: false, excludeNested: false).map{($0.isDefault ? defaultSectionMenuName : $0.name)}.sorted(by: {$0 < $1})
        
        SlideInMenu.shared.show(title: "Move To Section", options: options) { (section) in
            let selectedSection = selection.getSection(name: ((section == defaultSectionMenuName ? "" : section)!))!
            selection.selectedShortcut?.section = selectedSection
            selection.selectedShortcut?.sequence = MasterData.shared.nextShortcutSequence(section: selectedSection)
            selection.selectedShortcut?.save()
            selection.deselectShortcut()
            selection.selectSection(section: selectedSection)
            selection.updateShortcutSequence()
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
            if selection.editShortcut.copyPrivate {
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
            Utility.mainThread {
                selection.editShortcut.url = ""
                selection.editShortcut.urlSecurityBookmark = nil
                Utility.executeAfter(delay: 0) {
                    refresh.toggle()
                }
            }
       }, label: {
        Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .foregroundColor(Palette.background.faintText)
                    .frame(width: 20, height: 20)
        })
        .buttonStyle(PlainButtonStyle())
    }
    
    private func finderButton() -> some View {
        
        return Button(action: {
            StatusMenu.shared.defineAlways(onTop: false)
            SetupDetailView.findFile { (url, data) in
                Utility.mainThread {
                    selection.editShortcut.urlSecurityBookmark = data
                    selection.editShortcut.url = url.absoluteString
                    Utility.executeAfter(delay: 0) {
                        refresh.toggle()
                    }
                }
            }
        },label: {
            Image(systemName: "folder.fill")
                .frame(width: 24, height: 24)
                .foregroundColor(Palette.background.themeText)
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
    
    private func shortcutKey(key: Binding<String>, notify: @escaping (String)->(), disabled: @escaping ()->(Bool)) -> some View {
        
        return ShortcutKeyView(key: key, isSettingShortcutKey: $isSettingShortcutKey, isEnabled: { isEnabled && !disabled() }, notify: notify)
    }
    
    private func shortcutKeyNotify(_ key: String) {
        selection.objectWillChange.send()
    }
    
    private func sectionKeyNotify(_ key: String) {
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
