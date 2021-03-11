//
//  Main View.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 07/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct MainView : View {
    
    @ObservedObject private var displayState = DisplayStateViewModel()
    
    @State private var title = "Shortcuts"
    @State private var showSetup = false
    
    var body: some View {
        
        StandardView(navigation: true, animate: true, backgroundColor: Palette.alternate) {
            GeometryReader { (geometry) in
                ZStack {
                    VStack(spacing: 0) {
                        Banner(title: $title, back: false, optionMode: .buttons, options: [
                            BannerOption(image: AnyView(Image(systemName: "gearshape.fill").font(.largeTitle).foregroundColor(Palette.banner.text))) {
                                showSetup = true
                            },
                            BannerOption(image: AnyView(Image(systemName: "filemenu.and.selection").font(.largeTitle).foregroundColor(Palette.banner.text))) {
                                
                                let exclude = (displayState.selectedSection == nil ? [] : [displayState.selectedSection!])
                                
                                let options = MasterData.shared.sectionsWithShortcuts(excludeSections: exclude, excludeNested: true).map{($0.name == "" ? defaultSectionMenuName : $0.name)}
                                
                                SlideInMenu.shared.show(title: "Select Section", options: options) { (section) in
                                    let selectedSection = (section == defaultSectionMenuName ? "" : section)
                                    displayState.selectedSection = selectedSection
                                    if let selectedSection = selectedSection {
                                        UserDefault.currentSection.set(selectedSection)
                                    }
                                }
                            }
                        ])
                        HStack {
                            ShortcutListView(displayState: displayState)
                        }
                    }
                    if showSetup {
                        let selection = Selection()
                        SetupView(selection: selection) {
                            showSetup = false
                        }
                    }
                }
            }
        }
    }
}
