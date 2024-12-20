//
//  Shortcut Key View.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 25/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct ShortcutKeyView : View {
    @Binding var key: String
    @Binding var isSettingShortcutKey: Bool
    @State var topSpace: CGFloat = 10
    @State var isEnabled: ()->(Bool) = { true }
    @State var notify: ((String)->())?

    var body: some View {
        VStack {
#if canImport(AppKit)
            let enable = (isEnabled() || isSettingShortcutKey)
            InputTitle(title: "Shortcut key", topSpace: topSpace, isEnabled: enable)
            Spacer().frame(height: 8)
            HStack {
                Spacer().frame(width: 32)
                HStack {
                    Spacer().frame(width: 10)
                    Text(key)
                        .font(inputFont)
                        .foregroundColor(enable ? Palette.input.text : Palette.input.faintText)
                        .font(defaultFont)
                    Spacer()
                }
                .frame(width: 100, height: inputDefaultHeight)
                .background(Palette.input.background.opacity(enable ? 0.5 : 1.0))
                .cornerRadius(10)
                if enable {
                    Spacer().frame(width: 16)
                    Button(action: {
                        isSettingShortcutKey.toggle()
                        if isSettingShortcutKey {
                            ShortcutKeyMonitor.shared.startDefine(notify: notifyWrapper)
                        } else {
                            ShortcutKeyMonitor.shared.stopDefine()
                        }
                    }) {
                        Text(isSettingShortcutKey ? "Cancel" : (key == "" ? "Add" : "Change"))
                            .frame(width: 80, height: inputDefaultHeight)
                            .background(Palette.shortcutKeyButton.background)
                            .foregroundColor(Palette.shortcutKeyButton.text)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!enable)
                }
                Spacer().frame(width: 32)
                Text(isSettingShortcutKey ? "Press key to set or Backspace to clear" : "")
                    .font(messageFont)
                    .foregroundColor(Palette.background.themeText)
                    .frame(height: inputDefaultHeight)
                Spacer()
            }
            Spacer()
#endif
        }
        .frame(height: inputDefaultHeight + inputTopHeight + 24)
    }
    
    private func notifyWrapper(_ key: String) {
        self.key = key
#if canImport(AppKit)
        ShortcutKeyMonitor.shared.stopDefine()
#endif
        isSettingShortcutKey = false
        notify?(key)
    }
}
