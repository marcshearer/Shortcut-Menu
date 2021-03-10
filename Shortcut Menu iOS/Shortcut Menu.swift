//
//  Shortcut Menu.swift
//  Wots4T
//
//  Created by Marc Shearer on 15/01/2021.
//

import SwiftUI
import UIKit

@main
struct ShortcutMenu: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private var selection: Selection

    init() {
        MyApp.shared.start()
        selection = Selection()
        selection.selectSection(section: UserDefault.currentSection.string)
    }
    
    var body: some Scene {
        MyScene(selection: selection)
    }
}

struct MyScene: Scene {
    @State var selection: Selection
    
    var body: some Scene {
        WindowGroup {
            // SetupView(title: "Setup")
            MainView(selection: selection)
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        return true
    }
}
