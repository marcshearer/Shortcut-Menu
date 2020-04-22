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
    
    private var statusButtonText: NSTextField!
    private var statusButtonTextWidthConstraint: NSLayoutConstraint!
    private var statusButtonImage = NSImageView()
    private var statusMenu: NSMenu

    private var menuItemList: [String: NSMenuItem] = [:]
    
    private var currentSection: String = ""
    private var popover: NSPopover!
    
    // MARK: - Constructor - instantiate the status bar menu =========================================================== -
    
    override init() {
        
        self.statusMenu = NSMenu()
        self.statusMenu.autoenablesItems = false
        super.init()
        
        if let button = self.statusItem.button {
            // Re-purpose the status button since standard view didn't give the right vertical alignment

            Constraint.anchor(view: button.superview!, control: button, attributes: .top, .bottom)
            
            self.statusButtonImage.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(self.statusButtonImage)
          
            self.statusButtonText = NSTextField(labelWithString: "Shortcuts")
            self.statusButtonText.translatesAutoresizingMaskIntoConstraints = false
            self.statusButtonText.sizeToFit()
            self.statusButtonText.textColor = NSColor.black
            self.statusButtonText.font = NSFont.systemFont(ofSize: 12)
            button.addSubview(self.statusButtonText)
          
            self.menuClosedTitle()
            
            _ = Constraint.setHeight(control: button, height: NSApp.mainMenu!.menuBarHeight)
            
            Constraint.anchor(view: button, control: self.statusButtonImage, attributes: .leading, .top, .bottom)
            _ = Constraint.setWidth(control: self.statusButtonImage, width: 30)
            
            Constraint.anchor(view: button, control: self.statusButtonText, attributes: .centerY)
            Constraint.anchor(view: button, control: self.statusButtonText, to: self.statusButtonImage, toAttribute: .trailing, attributes: .leading)
            Constraint.anchor(view: button, control: self.statusButtonText, attributes: .trailing)
         }
        
        // Menu for current section and default section
        self.currentSection = UserDefaults.standard.string(forKey: "currentSection") ?? ""
        self.update()
        
        self.statusMenu.delegate = self
        
        self.statusItem.menu = self.statusMenu
    }
    
    // MARK: - Menu delegate handlers =========================================================== -
    
    internal func menuWillOpen(_ menu: NSMenu) {
        // Close definition window
        self.popover?.performClose(self)
        
        // Show dropdown menu
        self.menuOpenTitle()
    }
    
    internal func menuDidClose(_ menu: NSMenu) {
        self.menuClosedTitle()
    }
    
    // MARK: - Popover delegate handlers =========================================================== -

    internal func popoverDidShow(_ notification: Notification) {
        
    }
    
    internal func popoverDidClose(_ notification: Notification) {
        self.update()
    }
    
    // MARK: - Main routines to handle the status elements of the menu =========================================================== -
    
    public func update() {
        
        self.statusMenu.removeAllItems()
        
        self.setTitle((self.currentSection == "" ? "Shortcuts" : self.currentSection))
        
         if currentSection != "" {
            if self.addShortcuts(section: currentSection) > 0 {
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
    
    private func addShortcuts(section: String, to subMenu: NSMenu? = nil) -> Int {
        var added = 0
        
        for shortcut in master.shortcuts.filter({ $0.section?.name == section }).sorted(by: {$0.sequence < $1.sequence}) {
            self.addShortcut(shortcut: shortcut, to: subMenu)
            added += 1
        }
        return added
    }
    
    private func addShortcut(shortcut: ShortcutViewModel, to subMenu: NSMenu?) {
        var action: Selector?
        switch shortcut.type {
        case .clipboard:
            action = #selector(StatusMenu.copyToClipboard(_:))
        case .url:
            action = #selector(StatusMenu.executeUrl(_:))
        }

        self.addItem(shortcut.name, action: action, to: subMenu)
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
    
    private func setTitle(_ title: String) {
        if let constraint = self.statusButtonTextWidthConstraint {
            self.statusButtonText.removeConstraint(constraint)
        }
        self.statusButtonText.stringValue = title
        self.statusButtonText.sizeToFit()
        self.statusButtonTextWidthConstraint = Constraint.setWidth(control: self.statusButtonText, width: self.statusButtonText.frame.size.width)
    }
    
    private func menuOpenTitle() {
        self.statusButtonText.textColor = NSColor.white
        self.statusButtonImage.image = NSImage(named: "xmark.circle.fill")!
    }
    
    private func menuClosedTitle() {
        self.statusButtonText.textColor = menuBarTextColor
        self.statusButtonImage.image = NSImage(named: "shortcut")!
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
        let contentView = ContentView().environment(\.managedObjectContext, MasterData.context)

         // Create the window and set the content view.
        
        if self.popover == nil {
            // Create the popover
            let popover = NSPopover()
            popover.contentSize = NSSize(width: 400, height: 500)
            popover.behavior = .transient
            popover.delegate = self
            popover.contentViewController = NSHostingController(rootView: contentView)
            self.popover = popover
        }
        self.popover.show(relativeTo: statusItem.button!.bounds, of: statusItem.button!, preferredEdge: NSRectEdge.minY)
        self.popover.contentViewController?.view.window?.becomeKey()
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
    
    @objc private func copyToClipboard(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem {
            if let shortcut = self.master.shortcuts.first(where: {$0.name == menuItem.title}) {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(shortcut.value, forType: .string)
            }
        }
    }
    
     @objc private func executeUrl(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem {
            if let shortcut = self.master.shortcuts.first(where: {$0.name == menuItem.title}) {
                if let url = URL(string: shortcut.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(sender)
    }
}
