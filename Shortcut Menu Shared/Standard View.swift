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
    var backgroundColor: PaletteColor
    
    init(navigation: Bool = false, animate: Bool = false, backgroundColor: PaletteColor = Palette.background, @ViewBuilder content: ()->Content) {
        self.navigation = navigation
        self.animate = animate
        self.backgroundColor = backgroundColor
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
        GeometryReader { (geometry) in
        ZStack {
            backgroundColor.background
                .ignoresSafeArea()
            
            VStack {
                Spacer().frame(height: geometry.safeAreaInsets.top)
                self.content
            }
            SlideInMenuView()
            if messageBox.isShown {
                Palette.maskBackground
                VStack() {
                    Spacer()
                    HStack {
                        Spacer()
                        let width = min(geometry.size.width - 40, 400)
                        let height = min(geometry.size.height - 40, 250)
                        MessageBoxView(showIcon: width >= 400).frame(width: width, height: height)
                            .cornerRadius(20)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
        .animation(animate || messageBox.isShown ? .easeInOut(duration: 0.5) : nil)
        .noNavigationBar
        }
    }
}

