//
//  Status Menu.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 20/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Cocoa
import SwiftUI

protocol StatusMenuPopoverDelegate {
    var popover: NSPopover? {get set}
}

class StatusMenu: NSObject, NSMenuDelegate, NSPopoverDelegate {
    
    public static let shared = StatusMenu()
    
    public let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    private let master = MasterData.shared
    
    private var statusButtonImage = NSImageView()
    private var statusMenu: NSMenu

    private var menuItemList: [String: NSMenuItem] = [:]
    
    private var currentSection: String = ""
    private var definePopover: NSPopover!
    private var whisperPopover: NSPopover!
    
    private var definePopoverShowing = false
   
    // MARK: - Constructor - instantiate the status bar menu =========================================================== -
    
    override init() {
        
        self.statusMenu = NSMenu()
        self.statusMenu.autoenablesItems = false
        super.init()
        
        let button = self.statusItem.button!
        self.statusButtonImage.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(self.statusButtonImage)
        Constraint.anchor(view: button, control: self.statusButtonImage, attributes: .leading, .top, .bottom)
        _ = Constraint.setWidth(control: self.statusButtonImage, width: 30)
        _ = Constraint.setWidth(control: button, width: 30)
        self.changeImage(close: false)

        // Menu for current section and default section
        self.currentSection = UserDefaults.standard.string(forKey: "currentSection") ?? ""
        self.update()
        
        self.statusMenu.delegate = self
        
        self.statusItem.menu = self.statusMenu
    }
    
    // MARK: - Menu delegate handlers =========================================================== -
    
    internal func menuWillOpen(_ menu: NSMenu) {
        if definePopoverShowing {
            menu.cancelTrackingWithoutAnimation()
        }
        
        // Close definition window
        self.definePopover?.performClose(self)
    }
    
    internal func menuDidClose(_ menu: NSMenu) {
    }
    
    // MARK: - Popover delegate handlers =========================================================== -

    internal func popoverDidShow(_ notification: Notification) {
    }
    
    internal func popoverDidClose(_ notification: Notification) {
        self.update()
        self.changeImage(close: false)
        self.definePopoverShowing = false
    }
    
    // MARK: - Main routines to handle the status elements of the menu =========================================================== -
    
    public func update() {
        
        self.statusMenu.removeAllItems()
        
        if self.currentSection != "" {
            if let section = self.master.sections.first(where: { $0.name == self.currentSection }) {
                if section.shortcuts > 0 {
                    self.addItem(id: "sectionTitle", (self.currentSection == "" ? "Shortcuts" : self.currentSection))
                    self.menuItemList["sectionTitle"]?.isEnabled = false
                }
            }
        }
        
         if currentSection != "" {
            if self.addShortcuts(section: currentSection, inset: 5) > 0 {
                self.addSeparator()
            }
        }
       
        if self.addShortcuts(section: "") > 0 {
            self.addSeparator()
        }
        
        let nonEmptySections = self.master.sectionsWithShortcuts(excludeDefault: true)
        if  nonEmptySections > 1 || (nonEmptySections == 1 && self.currentSection == "") {
            
            if self.addOtherShortcuts() > 0 {
                self.addSeparator()
            }
            
            let sectionMenu = self.addSubmenu("Choose section")
            _ = self.addSections(to: sectionMenu)
        }
        self.addItem("Define shortcuts", action: #selector(StatusMenu.define(_:)), keyEquivalent: "d")
        
        self.addSeparator()
        
        self.addItem("Quit Shortcuts", action: #selector(StatusMenu.quit(_:)), keyEquivalent: "q")

    }
    
    private func addShortcuts(section: String, inset: Int = 0, to subMenu: NSMenu? = nil) -> Int {
        var added = 0
        
        for shortcut in master.shortcuts.filter({ $0.section?.name == section }).sorted(by: {$0.sequence < $1.sequence}) {
            self.addShortcut(shortcut: shortcut, inset: inset, to: subMenu)
            added += 1
        }
        return added
    }
    
    private func addShortcut(shortcut: ShortcutViewModel, inset: Int = 0, to subMenu: NSMenu?) {
        self.addItem(String(repeating: " ", count: inset) + shortcut.name, action: #selector(StatusMenu.actionShortcut(_:)), to: subMenu)
    }
    
    private func addSections(to subMenu: NSMenu) -> Int {
        var added = 0
        for section in master.sections.filter({ $0.name != currentSection && $0.shortcuts > 0 }).sorted(by: {$0.sequence < $1.sequence}) {
            self.addItem(section.menuName, action: #selector(StatusMenu.changeSection(_:)), to: subMenu)
            added += 1
        }
        return added
    }
    
    private func addOtherShortcuts() -> Int {
        var added = 0
        let subMenu = self.addSubmenu("Other shortcuts")
        for section in master.sections.filter({ $0.name != currentSection && $0.name != "" && $0.shortcuts > 0 }).sorted(by: {$0.sequence < $1.sequence}) {
            
            if section.shortcuts > 1 {
                let sectionMenu = self.addSubmenu(section.menuName, to: subMenu)
                added += self.addShortcuts(section: section.menuName, to: sectionMenu)
            } else {
                added += self.addShortcuts(section: section.name, to: subMenu)
            }
        }
        return added
    }
    
    func showPopover(popover: inout NSPopover?, view: AnyView) {
        if popover == nil {
            let newPopover = NSPopover()
            newPopover.behavior = .applicationDefined
            newPopover.contentSize = NSSize(width: 400, height: 500)
            newPopover.delegate = self
            popover = newPopover
        }
        popover?.contentViewController = NSHostingController(rootView: view)
        popover?.show(relativeTo: self.statusItem.button!.bounds, of: self.statusItem.button!, preferredEdge: .minY)
    }
    
    func bringToFront() {
        self.definePopover.contentViewController?.view.window?.makeKey()
    }
    
    func changeImage(close: Bool) {
        if close {
            self.statusButtonImage.image = NSImage(named: "ringCloseWhite")
            self.statusButtonImage.image?.isTemplate = true
        } else {
            self.statusButtonImage.image = NSImage(named: "shortcut")
            self.statusButtonImage.image?.isTemplate = false
        }
    }
    
    private func attributedString(_ string: String, fontSize: CGFloat? = nil) -> NSAttributedString {
        var attributes: [NSAttributedString.Key : Any] = [:]
        
        // Set color
        attributes[NSAttributedString.Key.foregroundColor] = NSColor.black
        
        // Set font size if specified
        if let fontSize = fontSize {
            attributes[NSAttributedString.Key.font] = NSFont.systemFont(ofSize: fontSize)
        }
        
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    // MARK: - Helper routines for the popup menu =========================================================== -

    private func addItem(id: String? = nil, _ text: String = "", action: Selector? = nil, keyEquivalent: String = "", to menu: NSMenu? = nil) {
        var menu = menu
        if menu == nil {
            menu = self.statusMenu
        }
        let menuItem = menu!.addItem(withTitle: text, action: action, keyEquivalent: keyEquivalent)
        if action == nil {
            menuItem.isEnabled = false
        } else {
            menuItem.target = self
        }
        if id != nil {
            self.menuItemList[id!] = menuItem
        }
    }
    
    private func addSubmenu(_ text: String, to menu: NSMenu? = nil) -> NSMenu {
        var menu = menu
        if menu == nil {
            menu = self.statusMenu
        }
        let subMenu = NSMenu(title: text)
        let menuItem = menu!.addItem(withTitle: text, action: nil, keyEquivalent: "")
        menu!.setSubmenu(subMenu, for: menuItem)
        return subMenu
    }
    
    private func addSeparator() {
        self.statusMenu.addItem(NSMenuItem.separator())
    }
    
    @objc private func define(_ sender: Any?) {
        // Create the window and set the content view.
        let contentView = ContentView().environment(\.managedObjectContext, MasterData.context)
        self.showPopover(popover: &self.definePopover, view: AnyView(contentView))
        self.definePopover.contentViewController?.view.window?.becomeKey()
        self.changeImage(close: true)
        self.definePopoverShowing = true
    }
    
    @objc private func changeSection(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem {
            if menuItem.title == defaultSectionMenuName {
                self.currentSection = ""
            } else {
                self.currentSection = menuItem.title
            }
            UserDefaults.standard.set(self.currentSection, forKey: "currentSection")
            self.update()
        }
    }
    
    @objc private func actionShortcut(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem {
            if let shortcut = self.master.shortcuts.first(where: {$0.name == menuItem.title.trimmingCharacters(in: .whitespacesAndNewlines)}) {
                
                func copyAction() {
                    
                    // Copy text to clipboard if non-blank
                    if !shortcut.copyText.isEmpty {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(shortcut.copyText, forType: .string)
                        
                        // Create the window and set the content view.
                        self.showPopover(popover: &self.whisperPopover,
                                         view: AnyView(WhisperView(header: (shortcut.copyMessage.isEmpty ? shortcut.copyText : shortcut.copyMessage),
                                                                   caption: "Copied to clipboard") ))
                        
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3, qos: .userInteractive) {
                            self.whisperPopover.close()
                        }
                    }
                }
                
                func urlAction(wait: Bool) {
                    
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (shortcut.copyText.isEmpty || !wait ? 0 : 3), qos: .userInteractive) {
                        // URL if non-blank
                        if !shortcut.url.isEmpty {
                            if let url = URL(string: shortcut.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }
                
                if !shortcut.copyText.isEmpty && shortcut.copyPrivate {
                    
                    LocalAuthentication.authenticate(reason: "reveal private data", completion: {
                        copyAction()
                        urlAction(wait: true)
                    }, failure: {
                        urlAction(wait: false)
                    })
                } else {
                    copyAction()
                    urlAction(wait: true)
                }
            }
        }
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(sender)
    }
}
