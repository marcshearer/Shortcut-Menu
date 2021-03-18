//
//  Actions.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 09/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

class Actions {
    
    static func shortcut(name: String, completion: ((String?)->())? = nil) {
        var message: String?
        if let shortcut = MasterData.shared.shortcuts.first(where: {$0.name == name}) {
            
            func copyAction() {
                
                // Copy text to clipboard if non-blank
                if !shortcut.copyText.isEmpty {
                    #if canImport(UIKit)
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = shortcut.copyText
                    #else
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(shortcut.copyText, forType: .string)
                    #endif
                    
                    message = "'\(shortcut.copyMessage.isEmpty ? shortcut.copyText : shortcut.copyMessage)' \n\ncopied to clipboard"
                }
            }
            
            func urlAction(wait: Bool) {
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (shortcut.copyText.isEmpty || !wait ? 0 : 3), qos: .userInteractive) {
                    // URL if non-blank
                    if !shortcut.url.isEmpty {
                        if let url = URL(string: shortcut.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                            
                            if shortcut.url.trim().left(5) == "file:" && shortcut.urlSecurityBookmark != nil {
                                // File links not supported on iOS
                            } else {
                                // Shortcut to a remote url
                                Actions.browseUrl(url: url)
                            }
                        }
                    }
                }
            }
            
            if !shortcut.copyText.isEmpty && shortcut.copyPrivate {
                
                LocalAuthentication.authenticate(reason: "Passcode must be entered to copy \(shortcut.copyMessage)", completion: {
                    copyAction()
                    urlAction(wait: true)
                    completion?(message)
                }, failure: {
                    urlAction(wait: false)
                    completion?("\(shortcut.copyMessage) not copied due to incorrect passcode entry")
                })
            } else {
                copyAction()
                urlAction(wait: true)
                completion?(message)
            }
        } else {
            completion?(nil)
        }
    }
    
    fileprivate static func browseUrl(url: URL) {
        #if canImport(UIKit)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        #else
            NSWorkspace.shared.open(url)
        #endif
    }
}
