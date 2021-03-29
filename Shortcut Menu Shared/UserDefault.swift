//
//  UserDefault.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 25/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import Foundation

enum UserDefault: String, CaseIterable {
    case currentSection
    case database
    case lastVersion
    case lastBuild
    case minVersion
    case minMessage
    case infoMessage
    
    public var name: String { "\(self)" }
    
    public var defaultValue: Any {
        switch self {
        case .currentSection:
            return ""
        case .database:
            return "unknown"
        case .lastVersion:
            return "0.0"
        case .lastBuild:
            return 0
        case .minVersion:
            return 0
        case .minMessage:
            return ""
        case .infoMessage:
            return ""}
    }
    
    public func set(_ value: Any) {
        UserDefaults.shared.set(value, forKey: self.name)
    }
    
    public var string: String {
        return UserDefaults.shared.string(forKey: self.name)!
    }
    
    public var int: Int {
        return UserDefaults.shared.integer(forKey: self.name)
    }
    
    public var bool: Bool {
        return UserDefaults.shared.bool(forKey: self.name)
    }
    
    public static func registerDefaults() {
        var initial: [String:Any] = [:]
        for value in UserDefault.allCases {
            initial[value.name] = value.defaultValue
        }
        UserDefaults.shared.register(defaults: initial)
    }
}
