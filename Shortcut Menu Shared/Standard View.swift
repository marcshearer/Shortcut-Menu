//
//  Standard View.swift
//  Wots4T
//
//  Created by Marc Shearer on 02/03/2021.
//

import SwiftUI

struct StandardView <Content> : View where Content : View {
    @ObservedObject var messageBox = MessageBox.shared
    var navigation: Bool
    @State var animate = false
    var content: Content
    
    init(navigation: Bool = false, @ViewBuilder content: ()->Content) {
        self.navigation = navigation
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
            SlideInMenuView()
            if messageBox.isShown {
                Color.black.opacity(0.3)
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
        .animation(messageBox.isShown ? .easeInOut(duration: 0.5) : nil)
        .noNavigationBar
    }
}

