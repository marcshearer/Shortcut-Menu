//
//  ContentView.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

enum SetupPanel {
    case sections
    case shortcuts
    case detail
    case all
}

struct SetupView: View {
        
    enum SetupSheet : Identifiable {
        case settings
        case showShared
        case replacements
        
        var id: Int {
            hashValue
        }
    }

    @ObservedObject var selection: Selection
    @State var title = "Define Shortcuts"
    @State var completion: (()->())?
    @State var backEnabled = true
    @State private var showSheet: SetupSheet?
    @State private var panel: SetupPanel = (MyApp.format == .phone ? .sections : .all)
    
    var body: some View {
        StandardView {
            GeometryReader { (formGeometry) in
                ZStack {
                    VStack(spacing: 0) {
                        
                        if MyApp.target == .iOS {
                            Banner(title: $title,
                                   backEnabled: $selection.canExit,
                                   backAction: {
                                    if selection.canExit {
                                        completion?()
                                    }
                                   })
                        }
                        
                        GeometryReader { geometry in
                            let formHeight: CGFloat = geometry.size.height
                            let sectionWidth: CGFloat = geometry.size.width * (panel == .all ? 0.25 : 1.0)
                            let shortcutWidth: CGFloat = geometry.size.width * (panel == .all ? 0.35 : 1.0)
                            let detailWidth: CGFloat = geometry.size.width * (panel == .all ? (selection.singleSection ? 0.65 : 0.40) : 1.0)
                            
                            HStack(spacing: 0) {
                                
                                if (panel == .sections || panel == .all) && !selection.singleSection {
                                    SetupSectionListView(selection: selection, panel: $panel, width: sectionWidth)
                                        .frame(width: sectionWidth, height: formHeight, alignment: .leading)
                                }
                                 
                                if panel == .all {
                                    Divider()
                                        .background(Palette.divider.background)
                                        .frame(width: 2.0)
                                }
                                
                                if panel == .shortcuts || panel == .all {
                                    SetupShortcutListView(selection: selection, panel: $panel, width: shortcutWidth, singleSection: selection.singleSection)
                                        .frame(width: shortcutWidth, height: formHeight, alignment: .leading)
                                }
                                
                                if panel == .all {
                                    Divider()
                                        .background(Palette.divider.background)
                                }
                                
                                if panel == .detail || panel == .all {
                                    SetupDetailView(selection: selection, panel: $panel)
                                        .frame(width: detailWidth, height: formHeight, alignment: .leading)
                                }
                            }
                            .background(Palette.background.background)
                        }
                    }
                    
                    if MyApp.target == .iOS {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button{
                                    SlideInMenu.shared.show(title: "Options", options: ["Shortcuts preferences", "Text Replacements Setup", "Show shared shortcuts", "About Shortcuts"], top: formGeometry.size.height - (slideInMenuRowHeight * 6), completion: optionSelected)
                                } label: {
                                    Image(systemName: "line.horizontal.3")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .padding(.all, 10)
                                        .frame(width: 50.0, height: 50.0, alignment: .center)
                                        .foregroundColor(Palette.bannerButton.text)
                                }
                                .background(Palette.bannerButton.background)
                                .clipShape(Circle())
                                .buttonStyle(PlainButtonStyle())
                                .shadow(radius: 2, x: 5, y: 5)
                                Spacer().frame(width: 10)
                            }
                            Spacer().frame(height: 10)
                        }
                        .mySheet(item: $showSheet) { (item) in
                            switch item {
                            case .settings:
                                SettingsView()
                            case .replacements:
                                ReplacementsView()
                            case .showShared:
                                let padding: CGFloat = (MyApp.target == .iOS ? 0.0 : 60.0)
                                ShowSharedView(width: formGeometry.size.width - padding, height: formGeometry.size.height - padding)
                            }
                        }
                    }
                }
                .onAppear {
                    Version.current.check()
                }
            }
        }
    }
    
    private func optionSelected(_ selected: String?) {
        if let selected = selected {
            switch selected {
            case "Shortcuts preferences":
                showSheet = .settings
            case "Text Replacements Setup":
                showSheet = .replacements
            case "Show shared shortcuts":
                showSheet = .showShared
            case "About Shortcuts":
                MessageBox.shared.show("A Shortcut Management app from\nShearer Online Ltd", showVersion: true)
            default:
                break
            }
        }
    }
}
