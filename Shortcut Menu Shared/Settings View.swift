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
    @State private var sharing = Settings.shared.shareShortcuts.value
        
    var body: some View {
        
        StandardView {
            
            if MyApp.target == .iOS {
                Banner(title: Binding.constant("Shortcuts Preferences"),
                       backAction: {
                       })
            }
            
            HStack {
                VStack {
                    
                    Spacer().frame(height: 20)
                    
                    InputToggle(title: "Share Shortcuts With Other Devices", text: "Share shortcuts with other devices", field: $sharing, isEnabled: true) { (switchedOn) in
                        if switchedOn != settings.shareShortcuts.value {
                            if switchedOn {
                                MessageBox.shared.show("Switching on sharing will make any shortcuts you choose to share visible on all devices logged in to your Apple ID\n\nThis might result in your shortcuts being revealed to others. Do not store any sensitive personal data in shared shortcuts\n\n Are you sure you want to switch on sharing?", fontSize: 20, buttons: .confirmCancel, showIcon: false) { (confirmed) in
                                    if confirmed {
                                        settings.shareShortcuts.value = sharing
                                    } else {
                                        sharing = false
                                        settings.objectWillChange.send()
                                    }
                                }
                            } else {
                                if MasterData.shared.sharedData {
                                    MessageBox.shared.show("Switching off sharing will disable sharing on all currently shared sections and shortcuts\n\nAny previously shared sections and shortcuts will only be visible on this device. Are you sure you want to switch off sharing?", fontSize: 20, buttons: .confirmCancel, showIcon: false) { (confirmed) in
                                        if confirmed {
                                            settings.shareShortcuts.value = sharing
                                            MasterData.shared.removeSharing()
                                        } else {
                                            sharing = true
                                            settings.objectWillChange.send()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
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
