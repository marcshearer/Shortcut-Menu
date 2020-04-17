//
//  Shortcut View Model.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 12/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import Foundation
import Combine

@objc public final class ShortcutViewModel: NSObject, ObservableObject, Identifiable {
    
    // Properties in core data model
    public let id: UUID
    @Published public var name:String
    @Published public var value: String
    @Published public var section: String
    @Published public var sequence: Int
    
    // Enabled properties
    @Published public var canEditValue:Bool = false
    @Published public var canEditSection: Bool = false
    
    // Other properties
    @Published public var canSave: Bool = false
    
    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(id: UUID, name: String, value: String, section: String, sequence: Int) {
        self.id = id
        self.name = name
        self.value = value
        self.section = section
        self.sequence = sequence
        
        super.init()
        
        Publishers.CombineLatest4($name, $value, $section, $sequence)
            .receive(on: RunLoop.main)
            .map { name, value, section, sequence in
                return !name.isEmpty && !value.isEmpty && !section.isEmpty && sequence != 0
            }
        .assign(to: \.canSave, on: self)
        .store(in: &cancellableSet)
        
        $name
            .receive(on: RunLoop.main)
            .map { name in
                return !name.isEmpty
            }
        .assign(to: \.canEditValue, on: self)
        .store(in: &cancellableSet)
        
        $name
            .receive(on: RunLoop.main)
            .map { name in
                return !name.isEmpty
            }
        .assign(to: \.canEditSection, on: self)
        .store(in: &cancellableSet)
    }
}

extension ShortcutViewModel: NSItemProviderReading, NSItemProviderWriting {
    
    static let itemProviderType: String = "com.sheareronline.shortcutmenu.shortcut"
    
    public static var writableTypeIdentifiersForItemProvider: [String] = [ShortcutViewModel.itemProviderType]
    
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
    
    public static var readableTypeIdentifiersForItemProvider: [String] = [ShortcutViewModel.itemProviderType]
    
    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> ShortcutViewModel {
        let propertyList: [String : String] = try JSONSerialization.jsonObject(with: data, options: []) as! [String : String]
        return ShortcutViewModel(id: UUID(uuidString: propertyList["id"] ?? "") ?? UUID(), name: "", value: "", section: "", sequence: 0)
    }
}
