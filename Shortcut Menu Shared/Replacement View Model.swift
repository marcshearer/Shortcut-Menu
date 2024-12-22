//
//  Replacement View Model.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 16/12/2024.
//  Copyright © 2024 Marc Shearer. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import CoreData
import UniformTypeIdentifiers

public class ReplacementViewModel : ObservableObject, Identifiable, Hashable {
    
    // Managed object context
    let context: NSManagedObjectContext! = MasterData.context

    // Properties in core data model
    public var id: UUID
    @Published public var token: String
    @Published public var name: String
    @Published public var replacement: String
    @Published public var allowedValues: String
    @Published public var expiry: Float
    @Published public var entered: Date?
    
    // Linked managed objects
    private var replacementMO: ReplacementMO?
        
    // Other properties
    @Published public var tokenError: String = ""
    @Published public var nameError: String = ""
    @Published public var canSave: Bool = false

    // Auto-cleanup
    private var cancellableSet: Set<AnyCancellable> = []
    
    // Hasher for lists - only dependent on id and shared
    public var listHasher: Int {
        var hasher = Hasher()
        hasher.combine(self.token)
        hasher.combine(self.replacement)
        return hasher.finalize()
    }
    
    init(id: UUID? = nil, token: String = "", name: String = "", replacement: String = "", allowedValues: String = "", expiry: Float = 0, entered: Date? = nil) {
        self.id = id ?? UUID()
        self.token = token
        self.name = name
        self.replacement = replacement
        self.allowedValues = allowedValues
        self.expiry = expiry
        self.entered = entered
        
        self.setupMappings()
    }

    convenience init(replacementMO: ReplacementMO) {
        self.init(token: replacementMO.token, name: replacementMO.name, replacement: replacementMO.replacement, allowedValues: replacementMO.allowedValues, expiry: replacementMO.expiry, entered: replacementMO.entered)
        self.replacementMO = replacementMO
    }
    
    private func setupMappings() {
        
        $token
            .receive(on: RunLoop.main)
            .map { (token) in
                return (token.isEmpty ? "Token must be non-blank" : (self.exists(token: token) ? "Token already exists" : (!ReplacementViewModel.validToken(token) ? "May only contain alphanumerics & dash" : "")))
            }
            .assign(to: \.tokenError, on: self)
            .store(in: &cancellableSet)
        
        $tokenError
            .receive(on: RunLoop.main)
            .map { (tokenError) in
                return (tokenError == "")
            }
            .assign(to: \.canSave, on: self)
            .store(in: &cancellableSet)
        
        $name
            .receive(on: RunLoop.main)
            .map { (name) in
                return (name.isEmpty ? "Name must be non-blank" : (self.exists(name: name) ? "Name already exists" : ""))
            }
            .assign(to: \.nameError, on: self)
            .store(in: &cancellableSet)
        
        Publishers.CombineLatest($tokenError, $nameError)
            .receive(on: RunLoop.main)
            .map { (tokenError, nameError) in
                return (tokenError == "" && nameError == "")
            }
            .assign(to: \.canSave, on: self)
            .store(in: &cancellableSet)
    }
    
    public static func == (lhs: ReplacementViewModel, rhs: ReplacementViewModel) -> Bool {
        lhs.token == rhs.token && lhs.name == rhs.name && lhs.replacement == rhs.replacement && lhs.id == rhs.id && lhs.allowedValues == rhs.allowedValues && lhs.expiry == rhs.expiry && lhs.entered == rhs.entered
    }
    
    public var isNew: Bool {
        return self.replacementMO == nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(token)
        hasher.combine(name)
        hasher.combine(replacement)
        hasher.combine(allowedValues)
        hasher.combine(expiry)
        hasher.combine(entered)
    }
    
    private func exists(token: String) -> Bool {
        return MasterData.shared.replacements.contains(where: {$0.token == token && $0.id != self.id})
    }
    
    private func exists(name: String) -> Bool {
        return MasterData.shared.replacements.contains(where: {$0.name == name && $0.id != self.id})
    }
    
    public func copy(from: ReplacementViewModel) {
        self.id = from.id
        self.token = from.token
        self.name = from.name
        self.replacement = from.replacement
        self.replacementMO = from.replacementMO
        self.allowedValues = from.allowedValues
        self.expiry = from.expiry
        self.entered = from.entered
    }
    
    public static func validToken(_ string: String) -> Bool {
        var validCharacters = CharacterSet.alphanumerics
        validCharacters.insert("-")
        return (string.rangeOfCharacter(from: validCharacters.inverted) == nil)
    }
    
    public func save() {
        // Note the default section is stored in both the local and cloud database if it is shared
        // Other sections are stored in the cloud if shared, local otherwise
        
        if self.replacementMO == nil {
            // Need to create cloud record
            self.replacementMO = ReplacementMO(context: context)
        }
        self.toManagedObject(replacementMO: self.replacementMO!)
        
        do {
            try context.save()
        } catch {
            fatalError("Error writing replacement")
        }
    }
    
    private func toManagedObject(replacementMO: ReplacementMO) {
        replacementMO.token = self.token
        replacementMO.name = self.name
        replacementMO.replacement = self.replacement
        replacementMO.allowedValues = self.allowedValues
        replacementMO.expiry = self.expiry
        replacementMO.entered = self.entered
    }
    
    public func remove() {
        if self.replacementMO != nil {
            context.delete(self.replacementMO!)
        }
        self.replacementMO = nil
        
        do {
            try context.save()
        } catch {
            fatalError("Error removing replacement")
        }
    }
    
    public class func expired(tokens replacements: Set<ReplacementViewModel>) -> Set<ReplacementViewModel> {
        var result: Set<ReplacementViewModel> = []
        let now = Date()
        for replacement in replacements {
            if replacement.expiry > 0 {
                let validUntil = Date(timeInterval: Double(replacement.expiry * 60 * 60), since: replacement.entered ?? Date(timeIntervalSince1970: 0))
                if validUntil < now {
                    result.formUnion(Set([replacement]))
                }
            }
        }
        return result
    }
}
