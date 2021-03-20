//
//  Shortcut Menu.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 15/01/2021.
//

import SwiftUI
import UIKit

@main
struct ShortcutMenu: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
     
    init() {
        MyApp.shared.start()
    }
    
    var body: some Scene {
            MyScene()
    }
}

struct MyScene: Scene {
    
    var body: some Scene {
        WindowGroup {
            GeometryReader { (geometry) in
                MainView()
                    .onAppear() {
                        MyApp.format = (min(geometry.size.width, geometry.size.height) < 600 ? .phone : .tablet)
                    }
            }
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        return true
    }
}
