//
//  Actions.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 09/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

class Actions {
    
    static func shortcut(shortcut: ShortcutViewModel, completion: ((String?,String?)->())? = nil) {
        var message: String?
        var copyText: String = ""
        var copyMessage: String = ""
        var urlString: String = ""
        
        var references: Set<ReplacementViewModel> = []
        
        func copyAction() {
            
            // Copy text to clipboard if non-blank
            if !copyText.isEmpty {
#if canImport(UIKit)
                let pasteboard = UIPasteboard.general
                pasteboard.string = copyText
#else
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(copyText, forType: .string)
                if urlString.isEmpty {
                    Actions.paste()
                }
#endif
                if MyApp.target == .iOS || !urlString.isEmpty {
                    message = "'\(copyMessage.isEmpty ? copyText : copyMessage)' \n\ncopied to clipboard"
                }
            }
        }
        
        func urlAction(wait: Bool) {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (shortcut.copyText.isEmpty || !wait ? 0 : 3), qos: .userInteractive) {
                    // URL if non-blank
                if !shortcut.url.isEmpty {
                    if shortcut.url.trim().left(5) == "file:" && shortcut.urlSecurityBookmark != nil {
#if os(macOS)
                        // Shortcut to a local file
                        var isStale: Bool = false
                        do {
                            let url = try URL(resolvingBookmarkData: shortcut.urlSecurityBookmark!, options: .withSecurityScope, bookmarkDataIsStale: &isStale)
                            if url.startAccessingSecurityScopedResource() {
                                NSWorkspace.shared.open(url)
                            }
                            url.stopAccessingSecurityScopedResource()
                        } catch {
                            completion?("Unable to access this file",error.localizedDescription)
                            return
                        }
#endif
                    } else {
                        // Shortcut to a remote url
                        if let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                            Actions.browseUrl(url: url)
                        }
                    }
                }
            }
        }
        
        // Replace tokens and accumulate references
        var newReferences: Set<ReplacementViewModel> = []
        if !shortcut.copyText.isEmpty {
            (copyText, newReferences) = shortcut.copyText.processTokens()
            references.formUnion(newReferences)
        }
        if !shortcut.copyMessage.isEmpty {
            copyMessage = shortcut.copyMessage.replacingTokens()
            references.formUnion(newReferences)
        } else {
            copyMessage = copyText
        }
        if !shortcut.url.isEmpty && (shortcut.url.trim().left(5) != "file:" && shortcut.urlSecurityBookmark == nil) {
            urlString = shortcut.url.replacingTokens()
            references.formUnion(newReferences)
        }
        
        // Check expired tokens
        let expired = ReplacementViewModel.expired(tokens: references).map{"'\($0.token.replacingOccurrences(of: "-", with: " "))'".capitalized}
        if expired.count > 0 {
            let message = "The \(Utility.toString(expired)) \(expired.count > 1 ? "tokens have" : "token has") expired"
            completion?(message, "Update \(expired.count > 1 ? "them" : "it") to continue")
        } else {
            // All OK - go ahead and execute
            if !shortcut.copyText.isEmpty && shortcut.copyPrivate {
                LocalAuthentication.authenticate(reason: "reveal private data", completion: {
                    copyAction()
                    urlAction(wait: true)
                    completion?(message, nil)
                }, failure: {
                    urlAction(wait: false)
                    completion?("\(shortcut.copyMessage) not copied due to incorrect passcode entry", nil)
                })
            } else {
                copyAction()
                urlAction(wait: true)
                completion?(message, nil)
            }
        }
    }
    
    fileprivate static func paste() {
        #if os(macOS)
        let event1 = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true); // cmd-v down
        event1?.flags = CGEventFlags.maskCommand;
        event1?.post(tap: CGEventTapLocation.cghidEventTap);
        
        let event2 = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: false) // cmd-v up
        event2?.post(tap: CGEventTapLocation.cghidEventTap)
        #endif
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
