//
//  ContentView.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct SetupView: View {
    
    @ObservedObject var selection: Selection
    @State var title = "Define Shortcuts"
    @State var completion: (()->())?
    @State var backEnabled = true

    var body: some View {
        StandardView {
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
                    let sectionWidth: CGFloat = geometry.size.width * 0.25
                    let shortcutWidth: CGFloat = geometry.size.width * 0.35
                    let detailWidth: CGFloat = geometry.size.width * 0.4
                    
                    HStack(spacing: 0) {
                        SetupSectionListView(selection: selection, width: sectionWidth).frame(width: sectionWidth, height: formHeight, alignment: .leading)
                        
                        Divider()
                            .background(Color.white)
                            .frame(width: 2.0)
                        
                        SetupShortcutListView(selection: selection, width: shortcutWidth).frame(width: shortcutWidth, height: formHeight, alignment: .leading)
                        
                        Divider()
                            .background(Color.white)
                        
                        SetupDetailView(selection: selection).frame(width: detailWidth, height: formHeight, alignment: .leading)
                    }
                    .background(Palette.background.background)
                }
            }
        }
    }
}
