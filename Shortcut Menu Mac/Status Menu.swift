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

class StatusMenuAdditional {
    var statusItem: NSStatusItem
    var section: SectionViewModel
    
    init(statusItem: NSStatusItem, section: SectionViewModel, tag: Int) {
        self.statusItem = statusItem
        self.statusItem.button?.tag = tag
        self.section = section
    }
}

class StatusMenuInfo {
    var menuTag: Int
    var shortcut: ShortcutViewModel?
    var menuItem: NSMenuItem
    
    init(menuTag: Int, shortcut: ShortcutViewModel?, menuItem: NSMenuItem) {
        self.menuTag = menuTag
        self.shortcut = shortcut
        self.menuItem = menuItem
    }
}

class StatusMenu: NSObject, NSMenuDelegate, NSPopoverDelegate, NSWindowDelegate {
    
    public static let shared = StatusMenu()
    
    public let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    private let master = MasterData.shared
    
    public var statusMenu: NSMenu
    public var statusMenuButton: NSButton
    public var statusMenuRefreshMenuItem: NSMenuItem?

    private var menuItemList: [Int: StatusMenuInfo] = [:] // Tag / MenuInfo
    private var menuItemReplace: [StatusMenuInfo] = []
    private var lastTag: Int = 0
    
    private var currentSection: String = ""
    fileprivate var whisperPopover: NSPopover!
    private var aboutPopover: NSPopover!
    private var showSharedPopover: NSPopover!
    
    private var defineWindowController: MenubarWindowController!
    private var settingsWindowController: MenubarWindowController!
    private var replacementsWindowController: MenubarWindowController!
    fileprivate var windowShowing = false
    public var selection = Selection()
    
    private var additionalStatusItemsSectionId: [UUID : StatusMenuAdditional] = [:]
    fileprivate var additionalStatusItemsTag: [Int: StatusMenuAdditional] = [:]
    
    public var displayedRemoteUpdates = 0
   
    // MARK: - Constructor - instantiate the status bar menu =========================================================== -
    
    override init() {
        
        self.statusMenu = NSMenu()
        self.statusMenu.autoenablesItems = false
        self.statusMenuButton = self.statusItem.button!
        self.statusMenuButton.registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.string])
        
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
        if windowShowing {
            menu.cancelTrackingWithoutAnimation()
            self.defineWindowController?.window?.close()
            self.settingsWindowController?.window?.close()
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
        self.windowShowing = false
        MessageBox.shared.hide()
    }
    
    // MARK: - Window delegate handlers =========================================================== -

    internal func windowWillClose(_ notification: Notification) {
        self.popoverDidClose(notification)
    }
    
    
    // MARK: - Main routines to handle the status elements of the menu =========================================================== -
    
    public func update() {
        var optionsAdded = false
        var othersAdded = false
        
        self.statusMenu.removeAllItems()
        self.menuItemList = [:]
        self.menuItemReplace = []
        lastTag = 0
        
        if self.currentSection != "" {
            if let section = self.master.sections.first(where: { $0.name == self.currentSection }) {
                if section.shortcuts.count > 0 {
                    if self.addShortcuts(section: section, title: String(self.currentSection == "" ? "Shortcuts" : self.currentSection), inset: 5) > 0 {
                        optionsAdded = true
                        self.addSeparator()
                    }
                }
            }
        }
       
        if let defaultSection = master.defaultSection {
            let added = self.addShortcuts(section: defaultSection, title: "Shortcuts", inset: 5)
            if added > 0 {
                optionsAdded = true
                othersAdded = true
            }
        }
        
        let nonEmptySections = self.master.getSections(withShortcuts: true, excludeDefault: true).count
        let otherSections = (nonEmptySections > 1 || (nonEmptySections == 1 && self.currentSection == ""))
        
        if otherSections {
            
            if self.addOtherShortcuts(inline: !optionsAdded, inset: 5) > 0 {
                othersAdded = true
            }
            if othersAdded {
                self.addSeparator()
            }
        }
        
        addHeading(title: "Admin")
        
        if otherSections {
            let sectionMenu = self.addSubmenu("Choose section", inset: 5)
            _ = self.addSections(to: sectionMenu)
        }
        
        let adminMenu = self.addSubmenu("Configuration", inset: 5)
        self.addItem("Define shortcuts", action: #selector(StatusMenu.define(_:)), keyEquivalent: "d", to: adminMenu)
        
        if Settings.shared.shareShortcuts.value {
            self.addItem("Show shared shortcuts", action: #selector(StatusMenu.showShared(_:)), keyEquivalent: "", to: adminMenu)
        }
        
        self.addItem("Replacements", action: #selector(StatusMenu.replacements(_:)), keyEquivalent: "r", to: adminMenu)
        self.addItem("Preferences", action: #selector(StatusMenu.settings(_:)), keyEquivalent: "p", to: adminMenu)
        self.statusMenuRefreshMenuItem = self.addItem("Refresh Shortcuts", action: #selector(StatusMenu.refresh(_:)), keyEquivalent: "r", to: adminMenu)
        self.addItem("About Shortcuts", action: #selector(StatusMenu.about(_:)), keyEquivalent: "", to: adminMenu)
        
        self.addItem("Quit Shortcuts", inset: 5, action: #selector(StatusMenu.quit(_:)), keyEquivalent: "q")

        self.setupAdditionalMenus()

    }
    
    func updateReplacements() {
        for statusMenuInfo in menuItemReplace {
            if let title = statusMenuInfo.shortcut?.name.replacingTokens() {
                statusMenuInfo.menuItem.title = title
            }
        }
    }
    
    private func setupAdditionalMenus() {
        for (_, item) in self.additionalStatusItemsSectionId {
            NSStatusBar.system.removeStatusItem(item.statusItem)
        }
        self.additionalStatusItemsSectionId = [:]
        var tag = 0
        for section in master.sections.filter({$0.menuTitle != "" && !$0.isDefault && $0.shortcuts.count > 0}).reversed() {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem.menu = NSMenu()
            tag += 1
            let statusMenuAdditional = StatusMenuAdditional(statusItem: statusItem, section: section, tag: tag)
            self.additionalStatusItemsSectionId[section.id] = statusMenuAdditional
            self.additionalStatusItemsTag[tag] = statusMenuAdditional
            statusItem.button?.attributedTitle = NSAttributedString(string: section.menuTitle, attributes: [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 15)])
            statusItem.button?.registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.string])
            
            var title: String?
            if !(section.shortcuts.first?.nestedSection?.inline ?? false) {
                title = section.name
            }
            self.addShortcuts(section: section, title: title, inset: 5, to: statusItem.menu)
            if section.temporary {
                self.addSeparator(to: statusItem.menu)
                addHeading(title: "Maintenance", to: statusItem.menu)
                let menuItem = self.addItem("Edit \(section.name) shortcuts", inset: 5, action: #selector(StatusMenu.define(_:)), to: statusItem.menu)
                menuItem.tag = tag
            }
        }
    }
    
    @discardableResult private func addShortcuts(section: SectionViewModel, title: String? = nil, inset fixedInset: Int? = nil, to subMenu: NSMenu? = nil) -> Int {
        var added = 0
        var inset: Int
        
        if let title = title {
            addHeading(title: title, to: subMenu)
            inset = fixedInset ?? 5
        } else {
            inset = fixedInset ?? 0
        }
        for shortcut in section.shortcuts.sorted(by: {$0.sequence < $1.sequence}) {
            if shortcut.action == .nestedSection, let nestedSection = shortcut.nestedSection {
                if nestedSection.shortcuts.count > 0 {
                    if nestedSection.inline || nestedSection.shortcuts.count == 1 {
                        if nestedSection.inline {
                            self.addSeparator(to: subMenu)
                            addHeading(title: nestedSection.name, to: subMenu)
                        }
                        self.addShortcuts(section: nestedSection, inset: inset, to: subMenu)
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
    
    func addHeading(title: String, to subMenu: NSMenu? = nil) {
        let attrString = NSAttributedString(string: title.uppercased(), attributes: [NSAttributedString.Key.font : NSFont.boldSystemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: NSColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1)])
        self.addItem(attributedText: attrString, to: subMenu)
    }
    
    @discardableResult private func addShortcut(shortcut: ShortcutViewModel, inset: Int = 5, to subMenu: NSMenu?) -> Int {
        var added = 0
        
        if shortcut.action != .setReplacement {
            self.addItem(shortcut: shortcut, shortcut.name, inset: inset, action: #selector(StatusMenu.actionShortcut(_:)), keyEquivalent: shortcut.keyEquivalent, to: subMenu)
            added += 1
        } else {
            if let replacement = MasterData.shared.replacements.first(where: {$0.token == shortcut.replacementToken}) {
                let allowed = replacement.allowedValues.split(at: ",")
                if allowed.count > 1 {
                    let subMenuEntry = self.addSubmenu(shortcut: shortcut, String(repeating: " ", count: inset) + shortcut.name, to: subMenu)
                    added += 1
                    for value in allowed {
                        self.addItem(shortcut: shortcut, value, inset: 0, action: #selector(StatusMenu.actionReplacement(_:)), keyEquivalent: shortcut.keyEquivalent, to: subMenuEntry)
                        added += 1
                    }
                }
            }
        }
        return added
    }
    
    private func addSections(to subMenu: NSMenu) -> Int {
        var added = 0
        for section in master.sections.filter({ $0.name != currentSection && (($0.shortcuts.count > 0 && $0.menuTitle == "") || $0.isDefault) }).sorted(by: {$0.sequence < $1.sequence}) {
            if section.isDefault || master.shortcuts.firstIndex(where: {$0.action == .nestedSection && $0.nestedSection?.id == section.id}) == nil {
                self.addItem(section.menuName, action: #selector(StatusMenu.changeSection(_:)), to: subMenu)
                added += 1
            }
        }
        return added
    }
    
    private func addOtherShortcuts(inline: Bool, inset: Int) -> Int {
        var added = 0
        var subMenu: NSMenu
        var inset = inset
        
        if !inline {
            subMenu = self.addSubmenu("Other shortcuts", inset: 5)
            inset = 0
        } else {
            subMenu = self.statusMenu
        }
        
        for section in master.sections.filter({ $0.name != currentSection && !$0.isDefault && $0.shortcuts.count > 0  && $0.menuTitle == "" }).sorted(by: {$0.sequence < $1.sequence}) {
            if master.shortcuts.firstIndex(where: {$0.action == .nestedSection && $0.nestedSection?.id == section.id}) == nil {
                if section.shortcuts.count > 1 {
                    let sectionMenu = self.addSubmenu(section.menuName, inset: inset, keyEquivalent: section.keyEquivalent, to: subMenu)
                    added += self.addShortcuts(section: section, to: sectionMenu)
                } else {
                    added += self.addShortcut(shortcut: section.shortcuts.first!, inset: inset, to: subMenu)
                }
            }
        }
        return added
    }
    
    fileprivate func whisper(button: NSButton? = nil, header: String? = nil, caption: String? = nil, size: NSSize? = nil, closeAfter: TimeInterval = 3, tight: Bool = false) {
        // Create the window and set the content view.
        let button = button ?? self.statusItem.button!
        self.showPopover(button: button, popover: &self.whisperPopover,
                         view: AnyView(WhisperView(header: header, caption: caption, tight: tight)), size: size,
                         backgroundColor: Palette.whisper.background)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + closeAfter, qos: .userInteractive) {
            self.whisperPopover.close()
        }
    }
    
    @objc private func about(_ sender: Any) {
        self.showPopover(button: self.statusItem.button!, popover: &self.aboutPopover,
                         view: AnyView(MessageBoxView().frame(width: 400, height: 250)), size: NSSize(width: 400, height: 250))
        MessageBox.shared.show("A Shortcut Management app from\nShearer Online Ltd", showVersion: true, completion: { (_) in
                self.aboutPopover.close()
        })
    }
    
    @objc private func showShared(_ sender: Any) {
        
        self.showPopover(button: self.statusItem.button!, popover: &self.showSharedPopover,
                         view: AnyView(ShowSharedView(minimumBanner: true,
                                                      completion: {
                                                            self.showSharedPopover.close()
                                                      })))
    }
    
    private func showPopover(button: NSButton, popover: inout NSPopover?, view: AnyView, size: NSSize? = nil, backgroundColor: Color = Palette.background.background) {
        if popover == nil {
            let newPopover = NSPopover()
            newPopover.behavior = .transient
            newPopover.contentSize = size ?? NSSize(width: 400, height: 500)
            newPopover.delegate = self
            popover = newPopover
        }
        popover?.contentViewController = NSHostingController(rootView: view)
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        if let frameView = popover?.contentViewController?.view.superview {
            // Make the triangle callout background color
            let backgroundView = NSView(frame: frameView.bounds)
            backgroundView.wantsLayer = true
            backgroundView.layer?.backgroundColor = backgroundColor.cgColor
            backgroundView.autoresizingMask = [.width, .height]
            frameView.addSubview(backgroundView, positioned: .below, relativeTo: frameView)
        }
        popover?.contentViewController?.view.window?.makeKeyAndOrderFront(self)
    }
    
    private func showMenubarWindow(menubarWindowController: inout MenubarWindowController?, view: AnyView, title: String, saveName: String, size: CGSize)  {
        var window: NSWindow?
        if menubarWindowController == nil {
            menubarWindowController = MenubarWindowController()
            window = NSWindow(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask: [.titled, .closable],
                backing: .buffered, defer: false)
            window?.title = title
            window?.delegate = self
            menubarWindowController?.window = window
        } else {
            window = menubarWindowController?.window
        }
        window?.center()
        window?.setFrameAutosaveName(saveName)
        window?.contentView = NSHostingView(rootView: view)
        window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func defineAlways(onTop: Bool) {
        self.defineWindowController?.window?.level = (onTop ? .floating : .normal)
    }
    
    public func settingsAlways(onTop: Bool) {
        self.settingsWindowController?.window?.level = (onTop ? .floating : .normal)
    }
    
    public func replacementsAlways(onTop: Bool) {
        self.replacementsWindowController?.window?.level = (onTop ? .floating : .normal)
    }
    
    public func bringToFront() {
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func changeImage(close: Bool) {
        if close {
            self.statusMenuButton.title = "􀁠"
        } else {
            let override = Settings.shared.menuTitle.value
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

    @discardableResult private func addItem(shortcut: ShortcutViewModel? = nil, _ text: String = "", attributedText: NSAttributedString? = nil, inset: Int = 0, action: Selector? = nil, keyEquivalent: String = "", to menu: NSMenu? = nil) -> NSMenuItem {
        var menu = menu
        var replaced = false
        if menu == nil {
            menu = self.statusMenu
        }
        var menuItem: NSMenuItem
        if attributedText == nil {
            let replacedText = text.replacingTokens()
            replaced = (text != replacedText)
            menuItem = menu!.addItem(withTitle: String(repeating: " ", count: inset) + replacedText, action: action, keyEquivalent: "")
        } else {
            menuItem = menu!.addItem(withTitle: "", action: action, keyEquivalent: "")
            menuItem.view = NSView(frame: NSRect(origin: CGPoint(), size: CGSize(width: max(200, menuItem.menu!.size.width), height: 18)))
            let text = NSTextField(labelWithAttributedString: attributedText!)
            menuItem.view!.addSubview(text, anchored: .bottom, .trailing)
            Constraint.anchor(view: menuItem.view!, control: text, constant: 15.0, attributes: .leading)
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
        if shortcut != nil {
            lastTag += 1
            let statusMenuInfo = StatusMenuInfo(menuTag: lastTag, shortcut: shortcut, menuItem: menuItem)
            self.menuItemList[lastTag] = statusMenuInfo
            if replaced {
                self.menuItemReplace.append(statusMenuInfo)
            }
            menuItem.tag = lastTag
        }
        return menuItem
    }
    
    private func addSubmenu(shortcut: ShortcutViewModel? = nil, _ text: String, inset: Int = 0, keyEquivalent: String = "", to menu: NSMenu? = nil) -> NSMenu {
        var menu = menu
        if menu == nil {
            menu = self.statusMenu
        }
        let replacedText = text.replacingTokens()
        let subMenu = NSMenu(title: replacedText)
        let menuItem = menu!.addItem(withTitle: String(repeating: " ", count: inset) + replacedText, action: nil, keyEquivalent: keyEquivalent)
        menu!.setSubmenu(subMenu, for: menuItem)
        if text != replacedText {
            menuItemReplace.append(StatusMenuInfo(menuTag: 0, shortcut: shortcut, menuItem: menuItem))
        }
        return subMenu
    }
    
    private func addSeparator(to menu: NSMenu? = nil) {
        let menu = menu ?? self.statusMenu
        menu.addItem(NSMenuItem.separator())
    }
    
    @objc func define(_ button: NSButton) {
        var section: SectionViewModel?
        if let additional = StatusMenu.shared.additionalStatusItemsTag[button.tag] {
            section = additional.section
        }
        define(section: section)
    }
    
    public func define(section: SectionViewModel? = nil) {
        if let section = section {
            self.selection.selectSection(section: section)
            selection.singleSection = true
            if let first = section.shortcuts.first(where: {$0.nestedSection == nil}) {
                selection.selectShortcut(shortcut: first)
            } else {
                selection.deselectShortcut()
            }
        } else {
            self.selection.deselectSection()
            selection.singleSection = false
        }
        
        // Create the window and set the content view.
        if !self.windowShowing {
                // Suspend any additional core data updates
            MasterData.shared.suspendRemoteUpdates(true)
                // Reload any pending changes
            if MasterData.shared.publishedRemoteUpdates > self.displayedRemoteUpdates {
                self.displayedRemoteUpdates = MasterData.shared.load()
            }
            
                // Display view
            let contentView = SetupView(selection: selection) {
                print("Exiting")
            }
            self.showMenubarWindow(menubarWindowController: &self.defineWindowController, view: AnyView(contentView), title: "Define Shortcuts", saveName: "Shortcuts Define Window", size: CGSize(width: defaultSectionWidth + defaultShortcutWidth + defaultDetailWidth, height: defaultFormHeight))
            self.defineWindowController.contentViewController?.view.window?.becomeKey()
            self.defineAlways(onTop: true)
            self.changeImage(close: true)
            self.windowShowing = true
        }
    }
    
    @objc public func settings(_ sender: Any?) {
        // Create the window and set the content view.
        if !self.windowShowing {

            // Display view
            let contentView = SettingsView()
            self.showMenubarWindow(menubarWindowController: &self.settingsWindowController, view: AnyView(contentView), title: "Preferences", saveName: "Shortcuts Settings Window", size: CGSize(width: 600, height: 300))
            self.settingsWindowController.contentViewController?.view.window?.becomeKey()
            self.settingsAlways(onTop: true)
            self.changeImage(close: true)
            self.windowShowing = true
        }
    }
    
    @objc public func replacements(_ sender: Any?) {
        // Create the window and set the content view.
        if !self.windowShowing {
            // Display view
            let contentView = ReplacementsView()
            self.showMenubarWindow(menubarWindowController: &self.replacementsWindowController, view: AnyView(contentView), title: "Text Replacements Setup", saveName: "Text Replacements Setup Window", size: CGSize(width: 600, height: 450))
            self.replacementsWindowController.contentViewController?.view.window?.becomeKey()
            self.replacementsAlways(onTop: true)
            self.changeImage(close: true)
            self.windowShowing = true
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
            if self.currentSection != "" {
                statusItem.button?.performClick(self)
            }
        }
    }
    
    @objc private func actionShortcut(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem {
            if let statusMenuInfo = menuItemList[menuItem.tag], let shortcut = statusMenuInfo.shortcut {
                self.actionShortcut(shortcut: shortcut)
            }
        }
    }
    
    @objc private func actionReplacement(_ sender: Any?) {
        if let menuItem = sender as? NSMenuItem {
            if let statusMenuInfo = menuItemList[menuItem.tag], let shortcut = statusMenuInfo.shortcut {
                if let replacement = MasterData.shared.replacements.first(where: {$0.token == shortcut.replacementToken}) {
                    replacement.replacement = menuItem.title
                    replacement.entered = Date()
                    replacement.save()
                    updateReplacements()
                }
            }
        }
    }
    
    private func actionShortcut(shortcut: ShortcutViewModel) {
        Actions.shortcut(shortcut: shortcut) { (message, caption) in
            if let message = message {
                self.whisper(header: message, caption: "Copied to clipboard", closeAfter: (caption == nil ? 1 : 5))
            }
        }
    }
    
    fileprivate func quickDrop(section: SectionViewModel, pasteboard: NSPasteboard) {
        if let urlString = pasteboard.string(forType: NSPasteboard.PasteboardType.URL) {
            // URL (hyperlink)
            if let url = URL(string: urlString) {
                LinkPresentation.getDetail(url: url, completion: { (result) in
                    var urlName = "Unknown URL"
                    Utility.mainThread { [self] in
                        switch result {
                        case .success(let (_, name)):
                            urlName = name ?? urlName
                        default:
                            break
                        }
                        createShortcut(section: section, name: urlName, url: urlString, action: .urlLink)
                    }
                })
            }
        } else if let fileUrlData = pasteboard.data(forType: NSPasteboard.PasteboardType.fileURL) {
            // File URL
            if let fileUrl = URL(dataRepresentation: fileUrlData, relativeTo: nil, isAbsolute: false) {
                if let bookmarkData = try? fileUrl.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                    let name =
                    fileUrl.deletingPathExtension().lastPathComponent.removingPercentEncoding ?? "Unknown file"
                    let url = fileUrl.absoluteString
                    let urlSecurityBookmark = bookmarkData
                    self.createShortcut(section: section, name: name, url: url, urlSecurityBookmark: urlSecurityBookmark, action: .urlLink)
                }
            }
        } else if let copyText = pasteboard.string(forType: NSPasteboard.PasteboardType.string) {
            // Plain String
            self.createShortcut(section: section, name: copyText, copyText: copyText, action: .clipboardText)
        }
    }
    
    private func createShortcut(section: SectionViewModel, name: String, url: String = "", urlSecurityBookmark: Data? = nil, copyText: String = "", action: ShortcutAction) {
        let shortcut = ShortcutViewModel()
        shortcut.section = section
        shortcut.name = name
        shortcut.url = url
        shortcut.urlSecurityBookmark = urlSecurityBookmark
        shortcut.copyText = copyText
        shortcut.action = action
        shortcut.sequence = (section.shortcuts.last?.sequence ?? 0) + 1
        master.shortcuts.append(shortcut)
        shortcut.save()
        refresh(nil)
    }
    
    private enum Source {
        case section
        case shortcut
        case mainMenu
    }
    
    public func updateShortcutKeys() {
        var keys: [(String, (Source, UUID))] = []
        
        // Main menu
        let key = Settings.shared.shortcutKey.value
        if key != "" {
            keys.append((key, (.mainMenu, defaultUUID)))
        }
    
        // Add additional sections
        let sectionKeys = master.sections.filter{$0.keyEquivalent != "" && !$0.isDefault}.map{($0.keyEquivalent, (Source.section, $0.id))}
        keys.append(contentsOf: sectionKeys)
        
        // Add shortcuts
        let shortcutKeys = master.shortcuts.filter{$0.keyEquivalent != ""}.map{($0.keyEquivalent, (Source.shortcut, $0.id))}
        keys.append(contentsOf: shortcutKeys)
        
        ShortcutKeyMonitor.shared.updateMonitor(keys: keys)
    }
    
    private func shortcutKeyNotify(_ id: Any?) {
        if let (source, shortcutId) = id as? (Source, UUID) {
            switch source {
            case .section:
                if let statusItem = additionalStatusItemsSectionId[shortcutId] {
                    statusItem.statusItem.button?.performClick(self)
                }
            case .shortcut:
                if let shortcut = master.shortcut(withId: shortcutId) {
                    actionShortcut(shortcut: shortcut)
                }
            case .mainMenu:
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
        if let additional = StatusMenu.shared.additionalStatusItemsTag[self.tag] {
            if let types = sender.draggingPasteboard.types {
                var found = false
                for type in types {
                    if additional.statusItem.button?.registeredDraggedTypes.contains(where: {$0 == type}) ?? false {
                        found = true
                    }
                }
                if found {
                    if let additional = StatusMenu.shared.additionalStatusItemsTag[self.tag] {
                        if additional.section.quickDrop && !StatusMenu.shared.windowShowing {
                            StatusMenu.shared.whisper(button: additional.statusItem.button, header: "Release mouse", caption: "to add shortcut", closeAfter: 60)
                        } else {
                            StatusMenu.shared.define(section: additional.section)
                        }
                    }
                }
            }
        }
        return .private
    }
    
    open override func draggingExited(_ sender: NSDraggingInfo?) {
        StatusMenu.shared.whisperPopover?.close()
    }
    
    open override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let additional = StatusMenu.shared.additionalStatusItemsTag[self.tag] {
            StatusMenu.shared.quickDrop(section: additional.section, pasteboard: sender.draggingPasteboard)
        }
        StatusMenu.shared.whisperPopover?.close()
        return true
    }
    
}
