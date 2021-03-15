//
//  Shortcut keys.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 13/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI
import Carbon.HIToolbox

struct ShortcutKey {
    public var key: String
    public var id: Any
    fileprivate var characters: String
    fileprivate var modifiers: NSEvent.ModifierFlags
}

class ShortcutKeyMonitor {
    
    static public var shared = ShortcutKeyMonitor()

    private var monitorNotify: ((Any)->())?
    private var monitorKeys: [String:[UInt:Any]] = [:]
    private var monitorContext: Any?
    private var defineNotify: ((String)->())?
    private var defineContext: Any?
    private var defineRestartMonitor = false
    
    // MARK: - Monitor shortcut key ======================================================================= -

    public func startMonitor(keys: [(key: String, id: Any)] = [], notify: @escaping (Any)->()) {
        let options = NSDictionary(object: kCFBooleanTrue!, forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString) as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if (trusted) {
            monitorNotify = notify
            monitorContext = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: monitorHandler)
        }
        if monitorContext != nil {
            updateMonitor(keys: keys)
        }
    }
    
    public func stopMonitor() {
        if let monitorContext = monitorContext {
            NSEvent.removeMonitor(monitorContext)
        }
        monitorContext = nil
        monitorNotify = nil
    }
    
    public func updateMonitor(keys: [(key: String, id: Any)]) {
        monitorKeys = [:]
        for key in keys {
            if let (characters, modifiers) = decompose(key: key.key) {
                if monitorKeys[characters] == nil {
                    monitorKeys[characters] = [:]
                }
                monitorKeys[characters]![modifiers.rawValue] = key.id
            }
        }
    }
    
    public func decompose(key: String) -> (String, NSEvent.ModifierFlags)? {
        var key = key
        var modifiers = NSEvent.ModifierFlags()
        if key.contains("⇧") {
            modifiers = modifiers.union(.shift)
            key = key.replacingOccurrences(of: "⇧", with: "")
        }
        if key.contains("⌃") {
            modifiers = modifiers.union(.control)
            key = key.replacingOccurrences(of: "⌃", with: "")
        }
        if key.contains("⌥") {
            modifiers = modifiers.union(.option)
            key = key.replacingOccurrences(of: "⌥", with: "")
        }
        if key.contains("⌘") {
            modifiers = modifiers.union(.command)
            key = key.replacingOccurrences(of: "⌘", with: "")
        }
        if key.count == 1 {
            return (key.lowercased(), modifiers)
        } else {
            var functionKey: Int
            switch key {
            case "F1":
                functionKey = NSF1FunctionKey
            case "F2":
                functionKey = NSF2FunctionKey
            case "F3":
                functionKey = NSF3FunctionKey
            case "F4":
                functionKey = NSF4FunctionKey
            case "F5":
                functionKey = NSF5FunctionKey
            case "F6":
                functionKey = NSF6FunctionKey
            case "F7":
                functionKey = NSF7FunctionKey
            case "F8":
                functionKey = NSF8FunctionKey
            case "F9":
                functionKey = NSF9FunctionKey
            case "F10":
                functionKey = NSF10FunctionKey
            case "F11":
                functionKey = NSF11FunctionKey
            case "F12":
                functionKey = NSF12FunctionKey
            default:
                return nil
            }
            modifiers = modifiers.union(.function)
            return (String(UnicodeScalar(UInt16(functionKey))!), modifiers)
        }
    }
    
    private func monitorHandler(event: NSEvent!) {
        // Ignore anything while defining
        if defineContext == nil {
            
            // Only allow shortcuts to command keys or function keys
            if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.function) {
                if let characters = event.charactersIgnoringModifiers {
                    let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
                    if let id = monitorKeys[characters]?[modifiers] {
                        monitorNotify?(id)
                    }
                }
            }
        }
    }
    
    // MARK: - Define shortcut key ======================================================================== -
    
    public func startDefine(notify: @escaping (String)->()) {
        let options = NSDictionary(object: kCFBooleanTrue!, forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString) as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if (trusted) {
            defineContext = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: defineHandler)
            defineNotify = notify
        }
    }
    
    public func stopDefine() {
        if let defineContext = defineContext {
            NSEvent.removeMonitor(defineContext)
        }
        defineContext = nil
        defineNotify = nil
    }
    
    private func defineHandler(event: NSEvent) -> NSEvent? {
        var char = event.charactersIgnoringModifiers ?? ""
        var key = ""
        var modified = false
        var ok = false
        
        if event.keyCode == kVK_Escape {
            // Escape pressed
        } else {
            if event.modifierFlags.intersection(.shift) == .shift {
                if char.uppercased() != char.lowercased() {
                    char = char.uppercased()
                } else {
                    key += "⇧"
                }
            }
            if event.modifierFlags.intersection(.control) == .control {
                key += "⌃"
            }
            if event.modifierFlags.intersection(.option) == .option {
                key += "⌥"
                modified = true
            }
            if event.modifierFlags.intersection(.command) == .command {
                key += "⌘"
                modified = true
            }
            if event.modifierFlags.intersection(.function) == .function {
                ok = true
                modified = true
                switch Int(char.unicodeScalars.first!.value) {
                case NSF1FunctionKey:
                    char = "F1"
                case NSF2FunctionKey:
                    char = "F2"
                case NSF3FunctionKey:
                    char = "F3"
                case NSF4FunctionKey:
                    char = "F4"
                case NSF5FunctionKey:
                    char = "F5"
                case NSF6FunctionKey:
                    char = "F6"
                case NSF7FunctionKey:
                    char = "F7"
                case NSF8FunctionKey:
                    char = "F8"
                case NSF9FunctionKey:
                    char = "F9"
                case NSF10FunctionKey:
                    char = "F10"
                case NSF11FunctionKey:
                    char = "F11"
                case NSF12FunctionKey:
                    char = "F11"
                default:
                    ok = false
                }
            } else {
                if char.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil {
                    ok = true
                } else if char == "+" || char == "-" || char == "=" || char == "?" || char == "!" || char == "/" {
                    ok = true
                }
            }
            
            if ok {
                if !modified {
                    key += "⌘"
                }
                key += char.uppercased()
                defineNotify?(key)
            } else {
                defineNotify?("")
            }
        }
        return nil
    }
}
