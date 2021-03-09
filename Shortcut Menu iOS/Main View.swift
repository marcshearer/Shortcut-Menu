//
//  Main View.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 07/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct MainView : View {
    
    @State private var title = "Shortcuts"
    @State private var showSetup = false
    @State var currentSection: String
    @State var selection = Selection()
    
    var body: some View {
        
        StandardView(navigation: true, animate: true) {
            GeometryReader { (geometry) in
                ZStack {
                    VStack(spacing: 0) {
                        Banner(title: $title, back: false, optionMode: .buttons, options: [
                            BannerOption(image: AnyView(Image(systemName: "gearshape.fill").font(.largeTitle).foregroundColor(Palette.banner.text))) {
                                showSetup = true
                            },
                            BannerOption(image: AnyView(Image(systemName: "filemenu.and.selection").font(.largeTitle).foregroundColor(Palette.banner.text))) {
                                
                                SlideInMenu.shared.show(title: "Select Section", options: MasterData.shared.sectionsWithShortcuts().map{($0.name == "" ? defaultSectionMenuName : $0.name)}) { (selection) in
                                    if let selection = selection {
                                        currentSection = selection
                                        UserDefault.currentSection.set(selection)
                                    }
                                }
                            }
                        ])
                        HStack {
                            ShortcutListView(currentSection: $currentSection)
                            .frame(width: geometry.size.width / 3)
                            Spacer()
                        }
                    }
                    if showSetup {
                        SetupView(selection: selection) {
                            showSetup = false
                        }
                    }
                }
            }
        }
    }
}
