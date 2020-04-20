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
        self.sectionMOs = self.fetch(from: "Section", sort: [(key: "sequence64", ascending: true)])
        
        self.shortcutMOs = self.fetch(from: "Shortcut", sort: [(key: "section", ascending: true),
                                                               (key: "sequence64", ascending: true)])
        
        // Build section list
        for sectionMO in self.sectionMOs {
            sections.append(SectionViewModel(sectionMO: sectionMO, master: self))
        }
        
        // Build shortcut list
        for shortcutMO in self.shortcutMOs {
            var section = sections.first(where: {$0.name == shortcutMO.section})
            if section == nil {
                // Section not found in current list - add it
                section = SectionViewModel()
                section?.name = shortcutMO.section
                section?.sequence = self.nextSectionSequence()
                sections.append(section!)
                section?.save()
            }
            shortcuts.append(ShortcutViewModel(shortcutMO: shortcutMO, section: section!, master: self))
        }
        
        // Make sure default section existst
        if self.sections.first(where: {$0.name == ""}) == nil {
            // Need to create a default section
            let defaultSection = SectionViewModel(id: UUID(), name: "", sequence: 1, master: self)
            sections.insert(defaultSection, at: 0)
            defaultSection.save()
        }
    }
    
    public func nextSectionSequence() -> Int {
        return self.sections.map { $0.sequence }.reduce(0) {max($0, $1)} + 1
    }

    public func nextShortcutSequence(section: SectionViewModel) -> Int {
        return self.shortcuts.filter {$0.section?.name == section.name}.map { $0.sequence }.reduce(0) {max($0, $1)} + 1
    }
    
    private func fetch<MO: NSManagedObject>(from entityName: String,
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
}
