//
//  Section View Model.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 12/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import Combine

public class SectionViewModel : ObservableObject, Identifiable {

    // Properties in core data model
    public let id: UUID
    @Published public var name:String
    @Published public var sequence: Int
    
    // Enabled properties
    
    // Other properties
    @Published public var canSave: Bool = false
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    convenience init() {
        self.init(id: UUID(), name: "", sequence: 0)
    }
    
    init(id: UUID, name: String, sequence: Int) {
        self.id = id
        self.name = name
        self.sequence = sequence
               
        self.setupMappings()
    }
    
    private func setupMappings() {
        
        $name
            .receive(on: RunLoop.main)
            .map { name in
                return !name.isEmpty
            }
        .assign(to: \.canSave, on: self)
        .store(in: &cancellableSet)
        
    }
    
    public func copy() -> SectionViewModel {
        return SectionViewModel(id: self.id, name: self.name, sequence: self.sequence)
    }
    
    public var displayName: String {
        if self.name == "" {
            return "No section"
        } else {
            return self.name
        }
    }
    
    public var itemProvider: NSItemProvider {
        return NSItemProvider(object: SectionItemProvider(id: self.id))
    }
}

@objc final class SectionItemProvider: NSObject, NSItemProviderReading, NSItemProviderWriting {
        
    public let id: UUID
    
    init(id: UUID) {
        self.id = id
    }
        
    static let itemProviderType: String = kUTTypeData as String
    
    public static var writableTypeIdentifiersForItemProvider: [String] {
        return [SectionItemProvider.itemProviderType]
    }
    
    public static var readableTypeIdentifiersForItemProvider: [String] {
        return [SectionItemProvider.itemProviderType]
    }
    
    public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        
        let progress = Progress(totalUnitCount: 1)
        
        do {
            let data = try JSONSerialization.data(withJSONObject: ["id" : self.id.uuidString], options: .prettyPrinted)
            progress.completedUnitCount = 1
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        
        return progress
    }
    
    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws ->SectionItemProvider {
        let propertyList: [String : String] = try JSONSerialization.jsonObject(with: data, options: []) as! [String : String]
        return SectionItemProvider(id: UUID(uuidString: propertyList["id"] ?? "") ?? UUID())
    }
    
    static public func dropAction(at index: Int, _ items: [NSItemProvider], selection: Selection, action: @escaping (Int, Int)->()) {
        DispatchQueue.main.async {
            for item in items {
                _ = item.loadObject(ofClass:SectionItemProvider.self) { (droppedItem, error) in
                    if error == nil {
                        if let droppedItem = droppedItem as?SectionItemProvider {
                            if let droppedIndex = selection.sections.firstIndex(where: {$0.id == droppedItem.id}) {
                                action(index, droppedIndex)
                            }
                        }
                    }
                }
            }
        }
    }
}


