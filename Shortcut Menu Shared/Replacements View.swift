//
//  Replacements View.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 16/12/2024.
//  Copyright © 2024 Marc Shearer. All rights reserved.
//

import SwiftUI

struct ReplacementsView : View {
    @State var replacement: ReplacementViewModel = ReplacementViewModel()
    @ObservedObject var editReplacement: ReplacementViewModel = ReplacementViewModel()
    @State var editAction: EditAction = .none
    @State var startAt: UUID?
    
    var body: some View {
        
        StandardView {
            
            VStack(spacing: 0) {
                if MyApp.target == .iOS {
                    Banner(title: Binding.constant("Text Replacements Setup"),
                           backAction: {
                    })
                }
                
                HStack(spacing: 0) {
                    
                    ReplacementsListView(replacement: $replacement, editReplacement: editReplacement, editAction: $editAction, startAt: $startAt)
                    
                }
            }
        }
    }
}

struct ReplacementsListView: View {
    @Binding var replacement: ReplacementViewModel
    @ObservedObject var editReplacement: ReplacementViewModel
    @State var showReplacement: ReplacementViewModel? = nil
    @Binding var editAction: EditAction
    @ObservedObject var data = MasterData.shared
    @Binding var startAt: UUID?

    var body: some View {
        VStack(spacing: 0.0) {
            ReplacementsListHeader(replacement: $replacement, editReplacement: editReplacement, editAction: $editAction, showReplacement: $showReplacement)
            ScrollViewReader { (scrollViewProxy) in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach (data.replacements) { (replacement) in
                            VStack(spacing: 0) {
                                HStack(spacing: 0) {
                                    Tile(dynamicText: {replacement.token}, selected: {replacement.id == self.editReplacement.id})
                                        .frame(width: 200)
                                    
                                    Divider()
                                        .background(Palette.divider.background)
                                        .frame(width: 2.0)
                                    
                                    Tile(dynamicText: {replacement.replacement}, selected: {replacement.id == self.editReplacement.id})
                                }
                                Divider()
                                    .background(Palette.divider.background)
                                    .frame(height: 2.0)
                            }
                            .id(replacement.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.replacement = replacement
                                editReplacement.copy(from: self.replacement)
                                editAction = .amend
                                showReplacement = editReplacement
                            }
                        }
                    }
                }
                .onChange(of: self.startAt, initial: false) { (_, newValue) in
                    Utility.executeAfter(delay: 0.5) {
                        scrollViewProxy.scrollTo(newValue, anchor: .center)
                    }
                }
                .listStyle(.plain)
           }
        }
        .sheet(item: $showReplacement) { (_) in
            ReplacementDetail(replacement: $replacement, editReplacement: editReplacement, startAt: $startAt, editAction: $editAction)
        }
        #if os(macOS)
        .frame(width: 600)
        #endif
    }
}

struct ReplacementsListHeader: View {
    @Binding var replacement: ReplacementViewModel
    @ObservedObject var editReplacement: ReplacementViewModel
    @Binding var editAction: EditAction
    @Binding var showReplacement: ReplacementViewModel?
    
    var body: some View {
        
        ZStack {
            HStack(spacing: 0) {
                Tile(text: "Token", color: Palette.header).frame(width: 200)
                Divider()
                    .background(Palette.divider.background)
                    .frame(width: 2.0)
                Tile(text: "Replacement", color: Palette.header)
                Spacer()
            }
            HStack(spacing: 0) {
                Spacer()
                if editAction == .none {
                    ToolbarButton("plus.circle.fill") {
                        replacement = ReplacementViewModel()
                        editReplacement.copy(from:replacement)
                        editAction = .create
                        showReplacement = editReplacement
                    }
                }
                Spacer().frame(width: 5.0)
            }
        }
        .frame(height: defaultRowHeight)
        .foregroundColor(Palette.header.text)
        .background(Palette.header.background)
    }
}

struct ReplacementDetail: View {
    @Binding var replacement: ReplacementViewModel
    @ObservedObject var editReplacement: ReplacementViewModel
    @Binding var startAt: UUID?
    @Binding var editAction: EditAction
    
    var body: some View {
        VStack(spacing: 0.0) {
            ReplacementDetailHeader(replacement: $replacement, editReplacement: editReplacement, startAt: $startAt, editAction: $editAction)
            
            Input(title: "Token", field: $editReplacement.token, message: $editReplacement.tokenError, placeHolder: "Must be non-blank", topSpace: 10, isEnabled: editAction != .none)
            
            Input(title: "Replacement Text", field: $editReplacement.replacement, topSpace: 10, isEnabled: editAction != .none)
            
            Input(title: "Allowed values (comma-separated)", field: $editReplacement.allowedValues, topSpace: 10, height: inputDefaultHeight * 3, isEnabled: editAction != .none)
            
            InputFloat(title: "Expires after (hours)", field: $editReplacement.expiry, topSpace: 10, places: 3)
            
            Spacer()
        }
        .frame(width: 400, height: 400)
    }
}

struct ReplacementDetailHeader: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var replacement: ReplacementViewModel
    @ObservedObject var editReplacement: ReplacementViewModel
    @Binding var startAt: UUID?
    @Binding var editAction: EditAction
    @State var title = ""

    var body: some View {
        
        ZStack {
            HStack(spacing: 0) {
                if editAction == .create {
                    Tile(text: "New Replacement", color: Palette.header)
                } else if editAction != .none {
                    Tile(text: "Replacement Detail", color: Palette.header)
                } else {
                    Tile(text: "Nothing Selected", color: Palette.header)
                }
                Spacer()
            }
            HStack(spacing: 0) {
                Spacer()
                ToolbarButton("trash.circle.fill") {
                    if let position = MasterData.shared.replacements.firstIndex(where: {$0.id == editReplacement.id}) {
                        MasterData.shared.replacements.remove(at: position)
                    }
                    editReplacement.remove()
                    editAction = .none
                    self.presentationMode.wrappedValue.dismiss()
                }
                Spacer().frame(width: 20.0)
                if editAction != .none {
                    if editReplacement.canSave {
                        ToolbarButton("checkmark.circle.fill") {
                            replacement.copy(from: editReplacement)
                            let newPosition = MasterData.shared.replacements.firstIndex(where: {$0.token > editReplacement.token}) ?? MasterData.shared.replacements.count
                            if replacement.isNew {
                                MasterData.shared.replacements.insert(replacement, at: newPosition)
                                startAt = editReplacement.id
                            } else {
                                let oldPosition = MasterData.shared.replacements.firstIndex(where: {$0.id == editReplacement.id})!
                                if newPosition != oldPosition {
                                    MasterData.shared.replacements.move(fromOffsets: IndexSet(integer: oldPosition), toOffset: newPosition)
                                    startAt = editReplacement.id
                                }
                            }
                            replacement.entered = Date()
                            replacement.save()
                            editAction = .none
                            MasterData.shared.objectWillChange.send()
                            self.presentationMode.wrappedValue.dismiss()
                            print(replacement.replacement.replacingTokens())
                        }
                        Spacer().frame(width: 5.0)
                    }
                    ToolbarButton("xmark.circle.fill") {
                        editAction = .none
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
                Spacer().frame(width: 5.0)
            }
        }
        .frame(height: defaultRowHeight)
        .foregroundColor(Palette.header.text)
        .background(Palette.header.background)
    }
}
