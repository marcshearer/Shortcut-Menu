//
//  Standard View.swift
//  Wots4T
//
//  Created by Marc Shearer on 02/03/2021.
//

import SwiftUI

struct StandardView <Content> : View where Content : View {
    @ObservedObject private var messageBox = MessageBox.shared
    var navigation: Bool
    var animate = false
    var content: Content
    
    init(navigation: Bool = false, animate: Bool = false, @ViewBuilder content: ()->Content) {
        self.navigation = navigation
        self.animate = animate
        self.content = content()
    }
        
    var body: some View {
        if navigation {
            NavigationView {
                contentView()
            }
            .navigationViewStyle(IosStackNavigationViewStyle())
        } else {
            contentView()
        }
    }
    
    private func contentView() -> some View {
        ZStack {
            Palette.tile.background
                .ignoresSafeArea()
            self.content
            if MyApp.target == .iOS {
                SlideInMenuView()
            }
            if messageBox.isShown {
                Palette.maskBackground
                VStack() {
                    Spacer()
                    HStack {
                        Spacer()
                        MessageBoxView().frame(width: 400, height: 250)
                            .cornerRadius(20)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .animation(animate || messageBox.isShown ? .easeInOut(duration: 0.5) : nil)
        .noNavigationBar
    }
}

