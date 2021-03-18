//
//  Slide In Menu.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 07/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

class SlideInMenu : ObservableObject {
    
    public static let shared = SlideInMenu()
    
    @Published public var title: String = ""
    @Published public var options: [String] = []
    @Published public var top: CGFloat = 0
    @Published public var width: CGFloat = 0
    @Published public var completion: ((String?)->())?
    @Published public var shown: Bool = false
    
    public func show(title: String, options: [String], top: CGFloat? = nil, width: CGFloat? = nil, completion: ((String?)->())? = nil) {
        withAnimation(.none) {
            SlideInMenu.shared.title = title
            SlideInMenu.shared.options = options
            SlideInMenu.shared.top = top ?? bannerHeight + 10
            SlideInMenu.shared.width = width ?? 300
            SlideInMenu.shared.completion = completion
            Utility.mainThread {
                SlideInMenu.shared.shown = true
            }
        }
    }
}

struct SlideInMenuView : View {
    @ObservedObject var values = SlideInMenu.shared
    
    @State private var animate = false
        
    var body: some View {
        
        GeometryReader { (fullGeometry) in
            GeometryReader { (geometry) in
                ZStack {
                    Rectangle()
                        .foregroundColor(values.shown ? Palette.maskBackground : Color.clear)
                        .onTapGesture {
                            values.shown = false
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    VStack(spacing: 0) {
                        Spacer().frame(height: values.top + fullGeometry.safeAreaInsets.top)
                        HStack {
                            Spacer()
                            VStack(spacing: 0) {
                                if values.title != "" {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Text(values.title)
                                                .font(.title)
                                                .foregroundColor(Palette.header.text)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                    .background(Palette.header.background)
                                    .frame(height: 50)
                                }
                                let options = $values.options.wrappedValue
                                List {
                                    ForEach(options, id: \.self) { (option) in
                                        VStack(spacing: 0) {
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Spacer().frame(width: 20)
                                                    Button(option, action: {
                                                        values.completion?(option)
                                                        values.shown = false
                                                    })
                                                    .animation(.none)
                                                    .foregroundColor(Palette.alternate.text)
                                                    .font(.title2)
                                                    Spacer()
                                                }
                                                Spacer()
                                            }
                                        }
                                        .frame(height: 50)
                                    }
                                    .background(Palette.alternate.background)
                                    .listRowInsets(EdgeInsets())
                                    .listStyle(PlainListStyle())
                                }
                                .environment(\.defaultMinListRowHeight, 50)
                                .frame(height: max(0, min(CGFloat(values.options.count * 50), fullGeometry.size.height - values.top - 100.0)))
                                VStack(spacing: 0) {
                                    Spacer()
                                    HStack {
                                        Spacer().frame(width: 20)
                                        Button("Cancel") {
                                            values.shown = false
                                        }
                                        .foregroundColor(Palette.alternate.text)
                                        .font(Font.title2.bold())
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .frame(height: 50).layoutPriority(.greatestFiniteMagnitude)
                            }
                            .frame(width: values.width)
                            .background(Palette.alternate.background)
                            .cornerRadius(20)
                            Spacer().frame(width: 20)
                        }
                        Spacer()
                    }
                    .offset(x: values.shown ? 0 : values.width + 20)
                }
            }
            .ignoresSafeArea()
            .onChange(of: values.shown, perform: { value in
                $animate.wrappedValue = true
            })
            .animation($animate.wrappedValue || values.shown ? .easeInOut : .none)
        }
    }
}
