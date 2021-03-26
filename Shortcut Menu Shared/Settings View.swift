//
//  Settings View.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 25/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct SettingsView : View {
    
    @ObservedObject var settings = Settings.shared
       
    @State private var isSettingShortcutKey = false
    
    var body: some View {
        
        StandardView {
            
            if MyApp.target == .iOS {
                Banner(title: Binding.constant("Shortcuts Preferences"),
                       backAction: {
                       })
            }
            
            HStack {
                VStack {
                    
                    InputToggle(title: "Share Shortcuts With Other Devices", text: "Shared shortcuts with other devices", field: $settings.shareShortcuts.value, isEnabled: true)
                    
                    if MyApp.target == .macOS {
                        
                        Input(title: "Menu bar title", field: $settings.menuTitle.value, placeHolder: "􀉑", width: 100, isEnabled: true)
                        
                        ShortcutKeyView(key: $settings.shortcutKey.value, isSettingShortcutKey: $isSettingShortcutKey)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: 450)
                
                Spacer()
            }
        }
    }
}
