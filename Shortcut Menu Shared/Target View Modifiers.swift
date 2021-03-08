//
//  Target View Modifiers.swift
//  Wots4T
//
//  Created by Marc Shearer on 26/02/2021.
//

import SwiftUI

struct NoNavigationBar : ViewModifier {
        
    #if canImport(UIKit)
    func body(content: Content) -> some View { content
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
    #else
    func body(content: Content) -> some View { content
        
    }
    #endif
}

extension View {
    var noNavigationBar: some View {
        self.modifier(NoNavigationBar())
    }
}

struct RightSpacer : ViewModifier {
        
    func body(content: Content) -> some View { content
        .frame(width: (MyApp.target == .iOS ? 16 : 32))
    }
}

extension View {
    var rightSpacer: some View {
        self.modifier(RightSpacer())
    }
}

struct BottomSpacer : ViewModifier {
        
    func body(content: Content) -> some View { content
        .frame(height: (MyApp.target == .iOS ? 0 : 16))
    }
}

extension View {
    var bottomSpacer: some View {
        self.modifier(BottomSpacer())
    }
}

#if canImport(UIKit)
typealias IosStackNavigationViewStyle = StackNavigationViewStyle
#else
typealias IosStackNavigationViewStyle = DefaultNavigationViewStyle
#endif

struct MyKeyboardTypeViewModifier : ViewModifier {
    @State var keyboardType: KeyboardType
    #if canImport(UIKit)
    func body(content: Content) -> some View { content
        .keyboardType(keyboardType)
    }
    #else
    func body(content: Content) -> some View { content
        
    }
    #endif
}

extension View {
    func myKeyboardType(_ keyboardType: KeyboardType) -> some View {
        self.modifier(MyKeyboardTypeViewModifier(keyboardType: keyboardType))
    }
}

#if canImport(UIKit)
typealias KeyboardType = UIKeyboardType
#else
enum KeyboardType {
    case `default`
    case URL
}
#endif

struct MyAutoCapitalizationViewModifier : ViewModifier {
    @State var autocapitalization: AutoCapitalization
    #if canImport(UIKit)
    func body(content: Content) -> some View { content
        .autocapitalization(autocapitalization)
    }
    #else
    func body(content: Content) -> some View { content
        
    }
    #endif
}

extension View {
    func myAutocapitalization(_ autoCapitalization: AutoCapitalization) -> some View {
        self.modifier(MyAutoCapitalizationViewModifier(autocapitalization: autoCapitalization))
    }
}

#if canImport(UIKit)
typealias AutoCapitalization = UITextAutocapitalizationType
#else
enum AutoCapitalization {
    case sentences
    case none
}
#endif
