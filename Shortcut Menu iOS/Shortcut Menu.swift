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
    private var currentSection: String

    init() {
        MyApp.shared.start()
        currentSection = UserDefault.currentSection.string
    }
    
    var body: some Scene {
        MyScene(currentSection: currentSection)
    }
}

struct MyScene: Scene {
    @State var currentSection: String
    
    var body: some Scene {
        WindowGroup {
            SetupView(title: "Setup")
            // MainView(currentSection: currentSection)
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        return true
    }
}
