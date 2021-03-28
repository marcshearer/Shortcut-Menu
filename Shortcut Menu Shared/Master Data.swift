//
//  Master Data.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 20/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import CoreData
import SwiftUI
import Combine

public class MasterData : ObservableObject {
    
    // Singleton for master data
    public static let shared = MasterData()
    
    // Core data context - set up in AppDelegate
    static var context: NSManagedObjectContext!
    static var backgroundContext: NSManagedObjectContext!

    //Remote update counters
    @Published private(set) var receivedRemoteUpdates = 0
    @Published private(set) var publishedRemoteUpdates = 0
    // Updated every 10 seconds (unless suspended)
    @Published private(set) var loadedRemoteUpdates = 0
    @Published private var remoteUpdatesSuspended = false
    private var observer: NSObjectProtocol?
    private var lastToken: NSPersistentHistoryToken?


    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    // Master data
    @Published var sections: [SectionViewModel] = []
    @Published var shortcuts: [ShortcutViewModel] = []
        
    // Core data
    private var sectionMOs: [SectionMO] = []
    private var shortcutMOs: [ShortcutMO] = []
    private var cloudSectionMOs: [CloudSectionMO] = []
    private var cloudShortcutMOs: [CloudShortcutMO] = []
    
    public var mainSections: [SectionViewModel] {
        self.sections.filter{!self.isNested($0)}
    }

    init() {
        self.observer = NotificationCenter.default.addObserver(forName: Notification.Name.persistentStoreRemoteChangeNotification, object: nil, queue: nil, using: { (notification) in
            Utility.mainThread {
                if self.haveReceivedUpdates() {
                    self.receivedRemoteUpdates += 1
                    Utility.debugMessage("MasterData", "Received \(self.receivedRemoteUpdates)", force: true)
                }
            }
        })
        self.setupMappings()
    }
    
    public func suspendRemoteUpdates(_ suspend: Bool) {
        if suspend != self.remoteUpdatesSuspended {
            self.remoteUpdatesSuspended = suspend
        }
    }
    
    private func setupMappings() {
        Publishers.CombineLatest($receivedRemoteUpdates, $remoteUpdatesSuspended)
            .receive(on: RunLoop.main)
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .map { (receivedRemoteUpdates, remoteUpdatesSuspended) in
                return (remoteUpdatesSuspended ? self.publishedRemoteUpdates : receivedRemoteUpdates)
            }
            .sink(receiveValue: { (newValue) in
                if self.publishedRemoteUpdates != newValue {
                    self.publishedRemoteUpdates = newValue
                }
            })
        .store(in: &cancellableSet)
    }
    
    @discardableResult public func load() -> Int {
        let startLoadreceivedRemoteUpdates = self.receivedRemoteUpdates
        Utility.debugMessage("load", "Loading \(startLoadreceivedRemoteUpdates)", force: true)
        
        self.sectionMOs = MasterData.fetch(from: SectionMO.tableName,
                                           sort: [(key: "sequence64", ascending: true)])
        self.cloudSectionMOs = MasterData.fetch(from: CloudSectionMO.tableName,
                                                sort: [(key: "sequence64", ascending: true)])
        
        self.shortcutMOs = MasterData.fetch(from: ShortcutMO.tableName,
                                            sort: [(key: "sectionId", ascending: true),
                                                   (key: "sequence64", ascending: true)])
        self.cloudShortcutMOs = MasterData.fetch(from: CloudShortcutMO.tableName,
                                                 sort: [(key: "sectionId", ascending: true),
                                                        (key: "sequence64", ascending: true)])
                
        // Build section list
        sections = []
        let cloudDefaultSectionExists = cloudSectionMOs.first(where: {$0.isDefault}) != nil
        for sectionMO in self.sectionMOs {
            if !sectionMO.isDefault || !cloudDefaultSectionExists {
                sections.append(SectionViewModel(sectionMO: sectionMO, shared: false))
            }
        }
        for sectionMO in self.cloudSectionMOs {
            sections.append(SectionViewModel(sectionMO: sectionMO, shared: true))
        }
        sections.sort(by: {$0.sequence < $1.sequence})

        // Build shortcut list
        shortcuts = []
        for shortcutMO in self.shortcutMOs {
            let shortcut = self.setupShortcut(shortcutMO: shortcutMO, shared: false)
            shortcuts.append(shortcut)
        }
        for shortcutMO in self.cloudShortcutMOs {
            let shortcut = self.setupShortcut(shortcutMO: shortcutMO, shared: true)
            shortcuts.append(shortcut)
        }
        shortcuts.sort(by: {Utility.lessThan([$0.section?.sequence ?? 0, $0.sequence], [ $1.section?.sequence ?? 0, $1.sequence])})

        // Make sure default section existst
        if self.sections.first(where: {$0.isDefault}) == nil {
            // Need to create a default section
            let defaultSection = SectionViewModel(id: defaultUUID, isDefault: true, name: "", sequence: 1)
            sections.insert(defaultSection, at: 0)
            defaultSection.save()
        }
        if startLoadreceivedRemoteUpdates == self.receivedRemoteUpdates {
            // No additional changes since start
            self.loadedRemoteUpdates = self.receivedRemoteUpdates
            return self.loadedRemoteUpdates
        } else {
            // Things have moved since load started - reload
            return self.load()
        }
    }
    
    func setupShortcut(shortcutMO: ShortcutBaseMO, shared: Bool) -> ShortcutViewModel {
        var section = sections.first(where: {$0.id == shortcutMO.sectionId})
        if section == nil {
            // Section not found in current list - add it
            section = SectionViewModel(id: shortcutMO.sectionId!)
            section?.sequence = self.nextSectionSequence()
            section?.name = shortcutMO.sectionId?.uuidString ?? "Error"
            sections.append(section!)
            section?.save()
        }
        let nestedSection = (shortcutMO.type == .section ? sections.first(where: {$0.id == shortcutMO.nestedSectionId}) : nil)
        return ShortcutViewModel(shortcutMO: shortcutMO, section: section!, nestedSection: nestedSection, shared: shared)
    }
    
    public func getSections(withShortcuts: Bool = false, excludeSections: [String] = [], excludeDescendents: Bool = true, excludeDefault: Bool = true, excludeNested: Bool = true) -> [SectionViewModel] {
        
        var descendents: [String] = []
        if excludeDescendents {
            for excludeSection in excludeSections {
                if let excludeSection = self.section(named: excludeSection) {
                    descendents.append(contentsOf: self.descendents(section:  excludeSection))
                }
            }
        }
        
        return self.sections.filter( { $0.shortcuts.count > 0 && (!excludeSections.contains($0.name)) && (!descendents.contains($0.name)) && (!excludeDefault || !$0.isDefault) && (!excludeNested || !isNested($0)) })
    }
    
    public func descendents(section: SectionViewModel) -> [String] {
        var result: [String] = []
        for shortcut in section.shortcuts {
            if shortcut.type == .section, let nestedSection = shortcut.nestedSection {
                result.append(nestedSection.name)
                result.append(contentsOf: descendents(section: nestedSection))
            }
        }
        return result
    }
    
    public func isNested(_ section: SectionViewModel?) -> Bool {
        var result = false
        if let section = section {
            result = self.shortcuts.first(where: {$0.type == .section && $0.nestedSection?.id == section.id}) != nil
        }
        return result
    }
    
    public func nestedParent(_ section: SectionViewModel?) -> SectionViewModel? {
        var result: SectionViewModel?
        if let section = section {
            result = self.shortcuts.first(where: {$0.type == .section && $0.nestedSection?.id == section.id})?.section
        }
        return result
    }
    
    public func section(named name: String) -> SectionViewModel? {
        return sections.first(where: {$0.name == name})
    }
    
    public func section(withId id: UUID) -> SectionViewModel? {
        return sections.first(where: {$0.id == id})
    }
    
    public var defaultSection: SectionViewModel? {
        return sections.first(where: {$0.isDefault})
    }

    public func shortcut(named name: String) -> ShortcutViewModel? {
        return shortcuts.first(where: {$0.name == name})
    }
    
    public func shortcut(withId id: UUID) -> ShortcutViewModel? {
        return shortcuts.first(where: {$0.id == id})
    }

    public func nextSectionSequence() -> Int {
        return self.sections.map { $0.sequence }.reduce(0) {max($0, $1)} + 1
    }

    public func nextShortcutSequence(section: SectionViewModel) -> Int {
        return self.shortcuts.filter {$0.section?.id == section.id}.map { $0.sequence }.reduce(0) {max($0, $1)} + 1
    }
    
    public var sharedData: Bool {
        var shared = false
        if !sections.filter({$0.shared}).isEmpty {
            shared = true
        } else if !shortcuts.filter({$0.shared}).isEmpty {
            shared = true
        }
        return shared
    }
    
    public func removeSharing() {
        for shortcut in shortcuts.filter({$0.shared}) {
            shortcut.shared = false
            shortcut.save()
        }
        for section in sections.filter({$0.shared}) {
            section.shared = false
            section.save()
        }
    }
    
    public static func fetch<MO: NSManagedObject>(from entityName: String,
                                            sort: [(key: String, ascending: Bool)] = []) -> [MO] {
        // Fetch an array of managed objects from core data
        var results: [MO] = []
        var read:[MO] = []
        let readSize = 100
        var finished = false
        var requestOffset: Int!
        
        // Create fetch request
        
        let request = NSFetchRequest<MO>(entityName: entityName)
        
        // Add any sort values
        if sort.count > 0 {
            var sortDescriptors: [NSSortDescriptor] = []
            for sortElement in sort {
                sortDescriptors.append(NSSortDescriptor(key: sortElement.key, ascending: sortElement.ascending))
            }
            request.sortDescriptors = sortDescriptors
        }
        
        while !finished {
            
            if let requestOffset = requestOffset {
                request.fetchOffset = requestOffset
            }
            
            read = []
            
            // Execute the query
            do {
                read = try MasterData.context.fetch(request)
            } catch {
                fatalError("Unexpected error")
            }
            
            results += read
            if read.count < readSize {
                finished = true
            } else {
                requestOffset = results.count
            }
        }
        
        return results
    }
    
    private func haveReceivedUpdates() -> Bool {
        var updates = false
        let fetchHistoryRequest = NSPersistentHistoryChangeRequest.fetchHistory(
            after: lastToken
        )

        if let historyResult = try? MasterData.backgroundContext.execute(fetchHistoryRequest)
            as? NSPersistentHistoryResult,
           let history = historyResult.result as? [NSPersistentHistoryTransaction] {
            for transaction in history {
                lastToken = transaction.token
                updates = true
            }
        } else {
            fatalError("Could not convert history result to transactions.")
        }
        return updates
    }
    
    public static func purgeTransactionHistory() {
        let yesterday = Date(timeIntervalSinceNow: TimeInterval(exactly: -24*60*60)!)
        let purgeRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: yesterday)
        try! MasterData.backgroundContext.execute(purgeRequest)
    }
}

extension Notification.Name {
    static let persistentStoreRemoteChangeNotification = Notification.Name(rawValue: "NSPersistentStoreRemoteChangeNotification")
}

protocol ManagedObject : NSManagedObject {
    static var tableName: String {get}
}
