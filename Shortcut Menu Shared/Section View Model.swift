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
    
    init(id: UUID, name: String, sequence: Int) {
        self.id = id
        self.name = name
        self.sequence = sequence
               
        Publishers.CombineLatest($name, $sequence)
            .receive(on: RunLoop.main)
            .map { name, sequence in
                return !name.isEmpty && sequence != 0
            }
        .assign(to: \.canSave, on: self)
        .store(in: &cancellableSet)
        
    }
}

