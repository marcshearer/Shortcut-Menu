//
//  Settings.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 25/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import Foundation

class Settings : ObservableObject {
    
    public static let shared = Settings()
    
    @Published var shareShortcuts   = Setting(false,            name: "shareShortcuts")
    @Published var menuTitle        = Setting("",               name: "menuTitle")
    @Published var shortcutKey      = Setting("",               name: "shortcutKey")
    @Published var authTimeout      = Setting(Float(60),        name: "authTimeout")
}

class Setting<Value> : ObservableObject {
    @Published public var value: Value {
        didSet {
            UserDefaults.shared.set(value, forKey: name)
        }
    }
    
    private let name: String
    
    init(_ defaultValue: Value, name: String) {
        self.name = "setting-\(name)"
        self.value = UserDefaults.shared.value(forKey: self.name) as? Value ?? defaultValue
    }
}

