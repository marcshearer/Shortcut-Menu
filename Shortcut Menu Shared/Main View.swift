//
//  Main View.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 07/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct MainView : View {
    
    @ObservedObject var data = MasterData.shared
    
    @State private var title = "Shortcuts"
    @State private var showSetup = false
    @State private var currentSection: SectionViewModel?
    
    init() {
        self.currentSection = data.sections.first(where: {$0.name == UserDefault.currentSection.string})
    }
    
    var body: some View {
        
        StandardView(navigation: true) {
            ZStack {
                VStack(spacing: 0) {
                    Banner(title: $title, back: false, optionMode: .buttons, options: [
                        BannerOption(image: AnyView(Image(systemName: "gearshape.fill").font(.largeTitle).foregroundColor(Palette.banner.text))) {
                            showSetup = true
                        },
                        BannerOption(image: AnyView(Image(systemName: "filemenu.and.selection").font(.largeTitle).foregroundColor(Palette.banner.text))) {
                            
                            SlideInMenu.shared.show(title: "Select Section", options: data.sections.map{($0.name == "" ? "Defaults only" : $0.name)}) { (selection) in
                                self.currentSection = data.sections.first(where: {$0.name == selection})
                                UserDefault.currentSection.set(selection ?? "")
                            }
                        }
                    ])
                    Spacer()
                    NavigationLink(destination: SetupView(), isActive: $showSetup) { EmptyView() }
                }
            }
        }
    }
}
