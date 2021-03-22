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
    @ObservedObject private var data = MasterData.shared
    
    @State public var selection = Selection()
    
    @State private var title = "Shortcuts"
    @State private var showSetup = false
    
    var body: some View {
        
        StandardView(navigation: true, animate: true, backgroundColor: Palette.alternate) {
            GeometryReader { (geometry) in
                ZStack {
                    VStack(spacing: 0) {
                        let updatesPending = (displayState.displayedRemoteUpdates < MasterData.shared.publishedRemoteUpdates)
                        let refreshOption = BannerOption(
                                image: bannerImage(name: "arrow.clockwise"),
                                hidden: { !updatesPending },
                                action: refresh)
                        let setupOption = BannerOption(
                                image: bannerImage(name: "gearshape.fill"),
                                action: setup)
                        let sectionOption = BannerOption(
                            image: bannerImage(name: "filemenu.and.selection"),
                                action: selectSection)
                        
                        Banner(title: $title, back: false, optionMode: .buttons, options: [refreshOption, setupOption, sectionOption])
                        
                        ShortcutListView(displayState: displayState)
                    }
                    if showSetup {
                        showSetupView()
                    }
                }
            }
        }
    }
    
    private func bannerImage(name: String) -> AnyView {
        AnyView(Image(systemName: name)
                        .font(.largeTitle)
                        .foregroundColor(Palette.banner.text))
    }
    
    private func refresh() {
        // Refersh the list
        displayState.displayedRemoteUpdates = MasterData.shared.load()
        displayState.refreshList()
    }
    
    private func setup() {
        // Suspend any additional core data updates
        MasterData.shared.suspendRemoteUpdates(true)
        // Reload any pending changes
        if MasterData.shared.publishedRemoteUpdates > displayState.displayedRemoteUpdates {
            displayState.displayedRemoteUpdates = MasterData.shared.load()
        }
        selection = Selection()
        showSetup = true
    }
    
    private func showSetupView() -> some View {
        SetupView(selection: selection) {
            MasterData.shared.suspendRemoteUpdates(false)
            displayState.refreshList()
            showSetup = false
        }
    }
    
    private func selectSection() {
        let exclude = (displayState.selectedSection == nil ? [] : [displayState.selectedSection!])
        
        let options = MasterData.shared.getSections(withShortcuts: true, excludeSections: exclude, excludeDefault: false, excludeNested: true).map{($0.isDefault ? defaultSectionMenuName : $0.name)}
        
        SlideInMenu.shared.show(title: "Change Section", options: options) { (section) in
            let selectedSection = (section == defaultSectionMenuName ? "" : section)
            displayState.selectedSection = selectedSection
            if let selectedSection = selectedSection {
                UserDefault.currentSection.set(selectedSection)
            }
        }
    }
}
