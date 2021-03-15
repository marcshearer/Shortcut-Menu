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

    // Core data
    private var sectionMOs: [SectionMO] = []
    private var shortcutMOs: [ShortcutMO] = []
    
    // View models
    @Published var sections: [SectionViewModel] = []
    @Published var shortcuts: [ShortcutViewModel] = []
        
    init() {
        
        // Fetch core data
        self.sectionMOs = MasterData.fetch(from: "Section", sort: [(key: "sequence64", ascending: true)])
        
        self.shortcutMOs = MasterData.fetch(from: "Shortcut", sort: [(key: "sectionId", ascending: true),
                                                               (key: "sequence64", ascending: true)])
 
        // Build section list
        for sectionMO in self.sectionMOs {
            sections.append(SectionViewModel(sectionMO: sectionMO, master: self))
        }
        
        // Build shortcut list
        for shortcutMO in self.shortcutMOs {
            var section = sections.first(where: {$0.id == shortcutMO.sectionId})
            if section == nil {
                // Section not found in current list - add it
                section = SectionViewModel(id: shortcutMO.sectionId!, master: MasterData.shared)
                section?.sequence = self.nextSectionSequence()
                section?.name = shortcutMO.sectionId?.uuidString ?? "Error"
                sections.append(section!)
                section?.save()
            }
            let nestedSection = (shortcutMO.type == .section ? sections.first(where: {$0.id == shortcutMO.nestedSectionId}) : nil)
            shortcuts.append(ShortcutViewModel(shortcutMO: shortcutMO, section: section!, nestedSection: nestedSection, master: self))
        }
        
        // Make sure default section existst
        if self.sections.first(where: {$0.isDefault}) == nil {
            // Need to create a default section
            let defaultSection = SectionViewModel(id: UUID(), isDefault: true, name: "", sequence: 1, master: self)
            sections.insert(defaultSection, at: 0)
            defaultSection.save()
        }

    }
    
    public func sectionsWithShortcuts(excludeSections: [String] = [], excludeDefault: Bool = true, excludeNested: Bool = true) -> [SectionViewModel] {
        return self.sections.filter( { $0.shortcuts.count > 0 && (!excludeSections.contains($0.name)) && (!excludeDefault || !$0.isDefault) && (!excludeNested || !isNested($0)) })
    }
    
    public func isNested(_ section: SectionViewModel) -> Bool {
        return self.shortcuts.first(where: {$0.type == .section && $0.nestedSection?.id == section.id}) != nil
    }
    
    public func section(named name: String) -> SectionViewModel? {
        return sections.first(where: {$0.name == name})
    }
    
    public var defaultSection: SectionViewModel? {
        return sections.first(where: {$0.isDefault})
    }

    public func shortcut(named name: String) -> ShortcutViewModel? {
        return shortcuts.first(where: {$0.name == name})
    }

    public func nextSectionSequence() -> Int {
        return self.sections.map { $0.sequence }.reduce(0) {max($0, $1)} + 1
    }

    public func nextShortcutSequence(section: SectionViewModel) -> Int {
        return self.shortcuts.filter {$0.section?.id == section.id}.map { $0.sequence }.reduce(0) {max($0, $1)} + 1
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
    
    private func backup() {
        let fileManager = FileManager()
        let (backupsUrl, assetsBackupUrl) = self.getDirectories()
        let dateString = Utility.dateString(Date(), format: backupDirectoryDateFormat, localized: false)
        let thisBackupUrl = backupsUrl.appendingPathComponent(dateString)
        _ = (try! fileManager.createDirectory(at: thisBackupUrl, withIntermediateDirectories: true))
        _ = (try! fileManager.createDirectory(at: assetsBackupUrl, withIntermediateDirectories: true))

        Backup.shared.backup(entity: SectionMO.entity(), groupName: "data", elementName: "Sections", directory: thisBackupUrl, assetsDirectory: assetsBackupUrl)
        Backup.shared.backup(entity: ShortcutMO.entity(), groupName: "data", elementName: "Shortcuts", directory: thisBackupUrl, assetsDirectory: assetsBackupUrl)
    }
    
    private func restore() {
        let (backupsUrl, assetsBackupUrl) = self.getDirectories()
        let dateString = "2021-03-15-10-31-22-391"
        let thisBackupUrl = backupsUrl.appendingPathComponent(dateString)
        
        Backup.shared.restore(directory: thisBackupUrl, assetsDirectory: assetsBackupUrl, entity: SectionMO.entity(), groupName: "data", elementName: "Sections")
        Backup.shared.restore(directory: thisBackupUrl, assetsDirectory: assetsBackupUrl, entity: ShortcutMO.entity(), groupName: "data", elementName: "Shortcuts")
    }
    
    private func getDirectories() -> (URL, URL) {
        let documentsUrl:URL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last! as URL
        let backupsUrl = documentsUrl.appendingPathComponent("backups")
        let assetsBackupUrl = backupsUrl.appendingPathComponent("assets")
        return (backupsUrl, assetsBackupUrl)
    }
}
