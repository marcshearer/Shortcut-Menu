//
//  Main View.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 07/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct MainView : View {
    
    @ObservedObject public var selection: Selection
    
    @State private var title = "Shortcuts"
    @State private var showSetup = false
    
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
                                
                                SlideInMenu.shared.show(title: "Select Section", options: selection.sectionsWithShortcuts().map{($0.name == "" ? defaultSectionMenuName : $0.name)}) { (section) in
                                    if let section = section {
                                        selection.selectSection(section: section)
                                        UserDefault.currentSection.set(selection)
                                    }
                                }
                            }
                        ])
                        HStack {
                            ShortcutListView(selection: selection)
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
