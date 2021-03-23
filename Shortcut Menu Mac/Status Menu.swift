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
    public var statusMenuRefreshMenuItem: NSMenuItem?

    private var menuItemList: [String: NSMenuItem] = [:]
    
    private var currentSection: String = ""
    private var defineWindowController: MenubarWindowController!
    private var whisperPopover: NSPopover!
    private var aboutPopover: NSPopover!
    private var showSharedPopover: NSPopover!
    
    private var defineWindowShowing = false
    
    private var additionalStatusItems: [UUID : NSStatusItem] = [:]
    
    public var displayedRemoteUpdates = 0
   
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
        self.updateShortcutKeys()
    }
    
    // MARK: - Menu delegate handlers =========================================================== -
    
    internal func menuWillOpen(_ menu: NSMenu) {
        self.statusMenuRefreshMenuItem?.isHidden = (self.displayedRemoteUpdates >= MasterData.shared.publishedRemoteUpdates)
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
        // Reload any pending changes
        if MasterData.shared.publishedRemoteUpdates > self.displayedRemoteUpdates {
            self.displayedRemoteUpdates = MasterData.shared.load()
        }
        // Update menus
        self.update()
        self.updateShortcutKeys()
        // Re-enable updates and continue
        MasterData.shared.suspendRemoteUpdates(false)
        self.changeImage(close: false)
        self.defineWindowShowing = false
        MessageBox.shared.hide()
    }
    
    // MARK: - Window delegate handlers =========================================================== -

    internal func windowWillClose(_ notification: Notification) {
        self.popoverDidClose(notification)
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
                if self.addShortcuts(section: section, inset: 5) > 0 {
                    self.addSeparator()
                }
            }
        }
       
        if let defaultSection = master.defaultSection {
            if self.addShortcuts(section: defaultSection) > 0 {
                self.addSeparator()
            }
        }
        
        let nonEmptySections = self.master.getSections(withShortcuts: true, excludeDefault: true).count
        if  nonEmptySections > 1 || (nonEmptySections == 1 && self.currentSection == "") {
            
            if self.addOtherShortcuts() > 0 {
                self.addSeparator()
            }
            
            let sectionMenu = self.addSubmenu("Choose section")
            _ = self.addSections(to: sectionMenu)
        }
        
        let adminMenu = self.addSubmenu("Configuration")
        self.addItem("Define shortcuts", action: #selector(StatusMenu.define(_:)), keyEquivalent: "d", to: adminMenu)
        
        self.addItem("Show shared shortcuts", action: #selector(StatusMenu.showShared(_:)), keyEquivalent: "", to: adminMenu)
        
        self.statusMenuRefreshMenuItem = self.addItem("Refresh Shortcuts", action: #selector(StatusMenu.refresh(_:)), keyEquivalent: "r", to: adminMenu)

        self.addItem("About", action: #selector(StatusMenu.about(_:)), keyEquivalent: "", to: adminMenu)
        
        self.addSeparator()
                
        self.addItem("Quit Shortcuts", action: #selector(StatusMenu.quit(_:)), keyEquivalent: "q")

        self.setupAdditionalMenus()

    }
    
    private func setupAdditionalMenus() {
        for (_, item) in self.additionalStatusItems {
            NSStatusBar.system.removeStatusItem(item)
        }
        self.additionalStatusItems = [:]
        for section in master.sections.filter({$0.menuTitle != "" && !$0.isDefault && $0.shortcuts.count > 0}) {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem.menu = NSMenu()
            self.additionalStatusItems[section.id] = statusItem
            statusItem.button?.attributedTitle = NSAttributedString(string: section.menuTitle, attributes: [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 15)])
            self.addShortcuts(section: section, to: statusItem.menu)
        }
    }
    
    @discardableResult private func addShortcuts(section: SectionViewModel, inset: Int = 0, to subMenu: NSMenu? = nil) -> Int {
        var added = 0
        
        for shortcut in section.shortcuts.sorted(by: {$0.sequence < $1.sequence}) {
            if shortcut.type == .section, let nestedSection = shortcut.nestedSection {
                if shortcut.nestedSection?.shortcuts.count ?? 0 > 0 {
                    if nestedSection.inline {
                        self.addSeparator(to: subMenu)
                        let attrString = NSAttributedString(string: nestedSection.name.uppercased(), attributes: [NSAttributedString.Key.font:NSFont.systemFont(ofSize: 10)])
                        self.addItem(attributedText: attrString, to: subMenu)
                        self.addShortcuts(section: nestedSection, inset: 5, to: subMenu)
                    } else {
                    let subMenuEntry = self.addSubmenu(String(repeating: " ", count: inset) + shortcut.name, to: subMenu)
                    self.addShortcuts(section: nestedSection, to: subMenuEntry)
                    }
                }
            } else {
                self.addShortcut(shortcut: shortcut, inset: inset, to: subMenu)
                added += 1
            }
        }
        return added
    }
    
    @discardableResult private func addShortcut(shortcut: ShortcutViewModel, inset: Int = 0, to subMenu: NSMenu?) -> Int {
        self.addItem(String(repeating: " ", count: inset) + shortcut.name, action: #selector(StatusMenu.actionShortcut(_:)), keyEquivalent: shortcut.keyEquivalent, to: subMenu)
        return 1
    }
    
    private func addSections(to subMenu: NSMenu) -> Int {
        var added = 0
        for section in master.sections.filter({ $0.name != currentSection && $0.shortcuts.count > 0 && $0.menuTitle == "" }).sorted(by: {$0.sequence < $1.sequence}) {
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
        for section in master.sections.filter({ $0.name != currentSection && !$0.isDefault && $0.shortcuts.count > 0  && $0.menuTitle == "" }).sorted(by: {$0.sequence < $1.sequence}) {
            if master.shortcuts.firstIndex(where: {$0.type == .section && $0.nestedSection?.id == section.id}) == nil {
                if section.shortcuts.count > 1 {
                    let sectionMenu = self.addSubmenu(section.menuName, to: subMenu)
                    added += self.addShortcuts(section: section, to: sectionMenu)
                } else {
                    added += self.addShortcut(shortcut: section.shortcuts.first!, to: subMenu)
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
    
    @objc private func about(_ sender: Any) {
        self.showPopover(popover: &self.aboutPopover,
                         view: AnyView(MessageBoxView().frame(width: 400, height: 250)), size: NSSize(width: 400, height: 250))
        MessageBox.shared.show("A Shortcut Management app from\nShearer Online Ltd", closeButton: true, showVersion: true, completion: {
                self.aboutPopover.close()
        })
    }
    
    @objc private func showShared(_ sender: Any) {
        
        self.showPopover(popover: &self.showSharedPopover,
                         view: AnyView(ShowSharedView(minimumBanner: true,
                                                      completion: {
                                                            self.showSharedPopover.close()
                                                      })))
    }
    
    private func showPopover(popover: inout NSPopover?, view: AnyView, size: NSSize? = nil) {
        if popover == nil {
            let newPopover = NSPopover()
            newPopover.behavior = .transient
            newPopover.contentSize = size ?? NSSize(width: 400, height: 500)
            newPopover.delegate = self
            popover = newPopover
        }
        popover?.contentViewController = NSHostingController(rootView: view)
        popover?.show(relativeTo: self.statusItem.button!.bounds, of: self.statusItem.button!, preferredEdge: .minY)
        if let frameView = popover?.contentViewController?.view.superview {
            // Make the triangle callout background color
            let backgroundView = NSView(frame: frameView.bounds)
            backgroundView.wantsLayer = true
            backgroundView.layer?.backgroundColor = Palette.background.background.cgColor
            backgroundView.autoresizingMask = [.width, .height]
            frameView.addSubview(backgroundView, positioned: .below, relativeTo: frameView)
        }
        popover?.contentViewController?.view.window?.makeKeyAndOrderFront(self)
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
            self.statusMenuButton.title = "􀁠"
        } else {
            let override = master.defaultSection?.menuTitle ?? ""
            self.statusMenuButton.title = override != "" ? override : "􀉑"
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

    @discardableResult private func addItem(id: String? = nil, _ text: String = "", attributedText: NSAttributedString? = nil, action: Selector? = nil, keyEquivalent: String = "", to menu: NSMenu? = nil) -> NSMenuItem {
        var menu = menu
        if menu == nil {
            menu = self.statusMenu
        }
        var menuItem: NSMenuItem
        if attributedText == nil {
            menuItem = menu!.addItem(withTitle: text, action: action, keyEquivalent: "")
        } else {
            menuItem = menu!.addItem(withTitle: "", action: action, keyEquivalent: "")
            menuItem.attributedTitle = attributedText
        }
        if keyEquivalent != "" {
            if let (characters, modifiers) = ShortcutKeyMonitor.shared.decompose(key: keyEquivalent) {
                menuItem.keyEquivalent = characters
                menuItem.keyEquivalentModifierMask = (modifiers.isEmpty ? [.command] : modifiers)
            }
        }

        if action == nil {
            menuItem.isEnabled = false
        } else {
            menuItem.target = self
        }
        if id != nil {
            self.menuItemList[id!] = menuItem
        }
        return menuItem
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
    
    private func addSeparator(to menu: NSMenu? = nil) {
        let menu = menu ?? self.statusMenu
        menu.addItem(NSMenuItem.separator())
    }
    
    @objc public func define(_ sender: Any?) {
        // Create the window and set the content view.
        if !self.defineWindowShowing {
            let selection = Selection()
            
            // Suspend any additional core data updates
            MasterData.shared.suspendRemoteUpdates(true)
            // Reload any pending changes
            if MasterData.shared.publishedRemoteUpdates > self.displayedRemoteUpdates {
                self.displayedRemoteUpdates = MasterData.shared.load()
            }
            
            // Display view
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
            statusItem.button?.performClick(self)
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
        var keys: [(String, (ShortcutType?, UUID))] = []
        
        // Main menu
        if let defaultSection = master.defaultSection {
            let key = defaultSection.keyEquivalent
            if key != "" {
                keys.append((key, (nil, defaultSection.id)))
            }
        }
        
        // Add additional sections
        let sectionKeys = master.sections.filter{$0.keyEquivalent != "" && !$0.isDefault}.map{($0.keyEquivalent, (ShortcutType.section, $0.id))}
        keys.append(contentsOf: sectionKeys)
        
        // Add shortcuts
        let shortcutKeys = master.shortcuts.filter{$0.keyEquivalent != ""}.map{($0.keyEquivalent, (ShortcutType.shortcut, $0.id))}
        keys.append(contentsOf: shortcutKeys)
        
        ShortcutKeyMonitor.shared.updateMonitor(keys: keys)
    }
    
    private func shortcutKeyNotify(_ id: Any?) {
        if let (type, shortcutId) = id as? (ShortcutType?, UUID) {
            switch type {
            case .section:
                if let statusItem = additionalStatusItems[shortcutId] {
                    statusItem.button?.performClick(self)
                }
            case .shortcut:
                if let shortcut = master.shortcut(withId: shortcutId) {
                    actionShortcut(shortcut: shortcut)
                }
            default:
                self.statusItem.button?.performClick(self)
            }
        }
    }

    @objc private func refresh(_ sender: Any?) {
        // Reload any pending changes
        if MasterData.shared.publishedRemoteUpdates > self.displayedRemoteUpdates {
            self.displayedRemoteUpdates = MasterData.shared.load()
            self.statusMenuRefreshMenuItem?.isHidden = true
        }
        self.update()
        self.updateShortcutKeys()
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
