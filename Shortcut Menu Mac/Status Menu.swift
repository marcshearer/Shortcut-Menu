//
//  Status Menu.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 20/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Cocoa
import SwiftUI
import UniformTypeIdentifiers

protocol StatusMenuPopoverDelegate {
    var popover: NSPopover? {get set}
}

class StatusMenu: NSObject, NSMenuDelegate, NSPopoverDelegate, NSWindowDelegate {
    
    public static let shared = StatusMenu()
    
    public let statusItem = NSStatusBar.system.statusItem(withLength: 15)
    
    private let master = MasterData.shared
    
    public var statusMenu: NSMenu
    public var statusMenuButton: NSButton

    private var menuItemList: [String: NSMenuItem] = [:]
    
    private var currentSection: String = ""
    private var defineWindowController: MenubarWindowController!
    private var whisperPopover: NSPopover!
    
    private var defineWindowShowing = false
    
    private var additionalStatusItems: [NSStatusItem] = []
   
    // MARK: - Constructor - instantiate the status bar menu =========================================================== -
    
    override init() {
        
        self.statusMenu = NSMenu()
        self.statusMenu.autoenablesItems = false
        self.statusMenuButton = self.statusItem.button!
        self.statusMenuButton.registerForDraggedTypes([NSPasteboard.PasteboardType.URL])

        super.init()
        
        self.changeImage(close: false)
        
        // Menu for current section and default section
        self.currentSection = UserDefault.currentSection.string
        self.update()
        
        self.statusMenu.delegate = self
        
        self.statusItem.menu = self.statusMenu
        
        ShortcutKeyMonitor.shared.startMonitor(notify: shortcutKeyNotify)
        updateShortcutKeys()
    }
    
    // MARK: - Menu delegate handlers =========================================================== -
    
    internal func menuWillOpen(_ menu: NSMenu) {
        if defineWindowShowing {
            menu.cancelTrackingWithoutAnimation()
            self.defineWindowController?.window?.close()
        }
        
    }
    
    internal func menuDidClose(_ menu: NSMenu) {
    }
    
    // MARK: - Popover delegate handlers =========================================================== -

    internal func popoverDidShow(_ notification: Notification) {
    }
    
    internal func popoverDidClose(_ notification: Notification) {
        self.update()
        self.changeImage(close: false)
        self.defineWindowShowing = false
    }
    
    // MARK: - Window delegate handlers =========================================================== -

    internal func windowWillClose(_ notification: Notification) {
        self.update()
        self.changeImage(close: false)
        self.defineWindowShowing = false
    }
    
    
    // MARK: - Main routines to handle the status elements of the menu =========================================================== -
    
    public func update() {
        
        self.statusMenu.removeAllItems()
        
        if self.currentSection != "" {
            if let section = self.master.sections.first(where: { $0.name == self.currentSection }) {
                if section.shortcuts.count > 0 {
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
        
        let nonEmptySections = self.master.sectionsWithShortcuts(excludeSections: [""]).count
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

        self.setupAdditionalMenus()

    }
    
    private func setupAdditionalMenus() {
        for item in self.additionalStatusItems {
            NSStatusBar.system.removeStatusItem(item)
        }
        self.additionalStatusItems = []
        for section in master.sections.filter({$0.menuTitle != "" && $0.shortcuts.count > 0}) {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem.menu = NSMenu()
            self.additionalStatusItems.append(statusItem)
            statusItem.button?.attributedTitle = NSAttributedString(string: section.menuTitle, attributes: [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 15)])
            self.addShortcuts(section: section.name, to: statusItem.menu)
        }
    }
    
    @discardableResult private func addShortcuts(section: String, inset: Int = 0, to subMenu: NSMenu? = nil) -> Int {
        var added = 0
        
        for shortcut in master.shortcuts.filter({ $0.section?.name == section }).sorted(by: {$0.sequence < $1.sequence}) {
            if shortcut.type == .section {
                if shortcut.nestedSection?.shortcuts.count ?? 0 > 0 {
                    let subMenuEntry = self.addSubmenu(String(repeating: " ", count: inset) + shortcut.name, to: subMenu)
                    self.addShortcuts(section: shortcut.nestedSection?.name ?? "Sub-entries", to: subMenuEntry)
                }
            } else {
                self.addShortcut(shortcut: shortcut, inset: inset, to: subMenu)
                added += 1
            }
        }
        return added
    }
    
    private func addShortcut(shortcut: ShortcutViewModel, inset: Int = 0, to subMenu: NSMenu?) {
        self.addItem(String(repeating: " ", count: inset) + shortcut.name, action: #selector(StatusMenu.actionShortcut(_:)), keyEquivalent: shortcut.keyEquivalent, to: subMenu)
    }
    
    private func addSections(to subMenu: NSMenu) -> Int {
        var added = 0
        for section in master.sections.filter({ $0.name != currentSection && $0.shortcuts.count > 0 }).sorted(by: {$0.sequence < $1.sequence}) {
            if master.shortcuts.firstIndex(where: {$0.type == .section && $0.nestedSection?.id == section.id}) == nil {
                self.addItem(section.menuName, action: #selector(StatusMenu.changeSection(_:)), to: subMenu)
                added += 1
            }
        }
        return added
    }
    
    private func addOtherShortcuts() -> Int {
        var added = 0
        let subMenu = self.addSubmenu("Other shortcuts")
        for section in master.sections.filter({ $0.name != currentSection && $0.name != "" && $0.shortcuts.count > 0 }).sorted(by: {$0.sequence < $1.sequence}) {
            if master.shortcuts.firstIndex(where: {$0.type == .section && $0.nestedSection?.id == section.id}) == nil {
                if section.shortcuts.count > 1 {
                    let sectionMenu = self.addSubmenu(section.menuName, to: subMenu)
                    added += self.addShortcuts(section: section.menuName, to: sectionMenu)
                } else {
                    added += self.addShortcuts(section: section.name, to: subMenu)
                }
            }
        }
        return added
    }
    
    func paste () {
        let event1 = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true); // cmd-v down
        event1?.flags = CGEventFlags.maskCommand;
        event1?.post(tap: CGEventTapLocation.cghidEventTap);

        let event2 = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: false) // cmd-v up
        event2?.post(tap: CGEventTapLocation.cghidEventTap)
    }
    
    private func whisper(header: String, caption: String = "", closeAfter: TimeInterval = 3) {
        // Create the window and set the content view.
        self.showPopover(popover: &self.whisperPopover,
                         view: AnyView(WhisperView(header: header,
                                                   caption: caption) ))
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + closeAfter, qos: .userInteractive) {
            self.whisperPopover.close()
        }
    }
    
    private func showPopover(popover: inout NSPopover?, view: AnyView) {
        if popover == nil {
            let newPopover = NSPopover()
            newPopover.behavior = .transient
            newPopover.contentSize = NSSize(width: 400, height: 500)
            newPopover.delegate = self
            popover = newPopover
        }
        popover?.contentViewController = NSHostingController(rootView: view)
        popover?.show(relativeTo: self.statusItem.button!.bounds, of: self.statusItem.button!, preferredEdge: .minY)
    }
    
     private func showMenubarWindow(menubarWindowController: inout MenubarWindowController?, view: AnyView)  {
        var window: NSWindow?
        if menubarWindowController == nil {
            menubarWindowController = MenubarWindowController()
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: defaultSectionWidth + defaultShortcutWidth + defaultDetailWidth, height: defaultFormHeight),
                styleMask: [.titled, .closable],
                backing: .buffered, defer: false)
            window?.title = "Define Shortcuts"
            window?.delegate = self
            menubarWindowController?.window = window
        } else {
            window = menubarWindowController?.window
        }
        window?.center()
        window?.setFrameAutosaveName("Shortcuts Define Window")
        window?.contentView = NSHostingView(rootView: view)
        window?.level = .floating
        window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func defineAlways(onTop: Bool) {
        self.defineWindowController?.window?.level = (onTop ? .floating : .normal)
    }
    
    public func bringToFront() {
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func changeImage(close: Bool) {
        if close {
            self.statusMenuButton.image = NSImage(systemSymbolName: "xmark.circle", accessibilityDescription: nil)!
        } else {
            self.statusMenuButton.image = NSImage(systemSymbolName: "arrowshape.turn.up.right.fill", accessibilityDescription: nil)!
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
    
    @objc public func define(_ sender: Any?) {
        // Create the window and set the content view.
        if !self.defineWindowShowing {
            let selection = Selection()
            let contentView = SetupView(selection: selection).environment(\.managedObjectContext, MasterData.context)
            self.showMenubarWindow(menubarWindowController: &self.defineWindowController, view: AnyView(contentView))
            self.defineWindowController.contentViewController?.view.window?.becomeKey()
            self.changeImage(close: true)
            self.defineWindowShowing = true
        }
    }
    
    @objc private func changeSection(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem {
            if menuItem.title == defaultSectionMenuName {
                self.currentSection = ""
            } else {
                self.currentSection = menuItem.title
            }
            UserDefault.currentSection.set(self.currentSection)
            self.update()
        }
    }
    
    @objc private func actionShortcut(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem {
            if let shortcut = self.master.shortcuts.first(where: {$0.name == menuItem.title.trim()}) {
                self.actionShortcut(shortcut: shortcut)
            }
        }
    }
    
    private func actionShortcut(shortcut: ShortcutViewModel) {
        
        func copyAction() {
            
            // Copy text to clipboard if non-blank
            if !shortcut.copyText.isEmpty {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(shortcut.copyText, forType: .string)
                
                if shortcut.url.isEmpty {
                    self.paste()
                } else {
                    self.whisper(header: shortcut.copyMessage.isEmpty ? shortcut.copyText : shortcut.copyMessage, caption: "Copied to clipboard")
                }
            }
        }
        
        func urlAction(wait: Bool) {
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (shortcut.copyText.isEmpty || !wait ? 0 : 3), qos: .userInteractive) {
                // URL if non-blank
                if !shortcut.url.isEmpty {
                    if let url = URL(string: shortcut.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                        
                        if shortcut.url.trim().left(5) == "file:" && shortcut.urlSecurityBookmark != nil {
                            // Shortcut to a local file
                            var isStale: Bool = false
                            do {
                                let url = try URL(resolvingBookmarkData: shortcut.urlSecurityBookmark!, options: .withSecurityScope, bookmarkDataIsStale: &isStale)
                                if url.startAccessingSecurityScopedResource() {
                                    NSWorkspace.shared.open(url)
                                }
                                url.stopAccessingSecurityScopedResource()
                            } catch {
                                self.whisper(header: "Unable to access this file", caption: error.localizedDescription)
                            }
                            
                        } else {
                            // Shortcut to a remote url
                            NSWorkspace.shared.open(url)
                        }
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
    
    public func updateShortcutKeys() {
        let shortcutKeys = master.shortcuts.filter{$0.keyEquivalent != ""}.map{($0.keyEquivalent, $0.name)}
        ShortcutKeyMonitor.shared.updateMonitor(keys: shortcutKeys)
    }
    
    private func shortcutKeyNotify(_ id: Any?) {
        if let name = id as? String,
           let shortcut = master.shortcut(named: name) {
            actionShortcut(shortcut: shortcut)
        }
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(sender)
    }    
}

class MenubarWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension NSStatusBarButton {
    
    open override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        StatusMenu.shared.define(self)
        return .private
    }
}
