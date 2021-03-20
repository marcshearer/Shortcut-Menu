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
    @State private var showShared = false
    @State private var sharedList: [(highlight: Bool, name: String)] = []

    var body: some View {
        StandardView() {
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
                            let sectionWidth: CGFloat = geometry.size.width * 0.25
                            let shortcutWidth: CGFloat = geometry.size.width * 0.35
                            let detailWidth: CGFloat = geometry.size.width * 0.4
                            
                            HStack(spacing: 0) {
                                SetupSectionListView(selection: selection, width: sectionWidth)
                                    .frame(width: sectionWidth, height: formHeight, alignment: .leading)
                                
                                Divider()
                                    .background(Color.white)
                                    .frame(width: 2.0)
                                
                                SetupShortcutListView(selection: selection, width: shortcutWidth)
                                    .frame(width: shortcutWidth, height: formHeight, alignment: .leading)
                                
                                Divider()
                                    .background(Color.white)
                                
                                SetupDetailView(selection: selection)
                                    .frame(width: detailWidth, height: formHeight, alignment: .leading)
                            }
                            .background(Palette.background.background)
                        }
                    }
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button{
                                sharedList = [(false, "Downloading shared shortcuts...")]
                                showShared = true
                            } label: {
                                Image(systemName: "icloud.and.arrow.up")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(.all, 5)
                                    .frame(width: 40.0, height: 40.0, alignment: .center)
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
                    .mySheet(isPresented: $showShared, content: {
                        let padding: CGFloat = (MyApp.target == .iOS ? 0.0 : 60.0)
                        ShowSharedView(sharedList: $sharedList, width: formGeometry.size.width - padding, height: formGeometry.size.height - padding)
                    })
                }
            }
        }
    }
}
