//
//  Show Shared View.swift
//  Shortcut Menu
//
//  Created by Marc Shearer on 19/03/2021.
//  Copyright © 2021 Marc Shearer. All rights reserved.
//

import SwiftUI

struct ShowSharedView : View {
    
    @State var title = "Shared Shortcuts"
    @Binding var sharedList: [(highlight: Bool, name: String)]
    @State var width: CGFloat = 400
    @State var height: CGFloat = 300
    @State var sections: [(id: String, name: String)] = []
    @State var shortcuts: [(sectionId: String, name: String)] = []
       
    var body: some View {
        
        VStack(spacing: 0) {
            Banner(title: $title)
            ScrollView {
            VStack {
                ForEach(sharedList, id: \.self.name) { (entry) in
                    HStack {
                        Spacer().frame(width: 32)
                        if entry.highlight {
                            Text(entry.name)
                                .foregroundColor(Palette.background.contrastText)
                                .font(.headline)
                                .bold()
                        } else {
                            Spacer().frame(width: 32)
                            Text(entry.name)
                                .foregroundColor(Palette.background.text)
                        }
                        Spacer()
                    }
                }
            }
            Spacer()
            }
        }
        .onAppear() {
            self.downloadShared()
        }
        .frame(width: width, height: height)
        .background(Palette.background.background)
    }
    
    private func downloadShared() {
        sections = []
        shortcuts = []
        let predicate = NSPredicate(format: "CD_shared = true")
        ICloud.shared.download(
            recordType: "CD_\(CloudSectionMO.tableName)",
            database: ICloud.shared.privateDatabase,
            keys: ["CD_id", "CD_name"],
            sortKey: ["CD_name"],
            predicate: predicate,
            downloadAction: { (record) in
                                let name = record.value(forKey: "CD_name") as! String
                sections.append((record.value(forKey: "CD_id") as! String, (name == "" ? defaultSectionDisplayName : name)))
                            },
            completeAction: {
                                let predicate = NSPredicate(format: "CD_type16 = %d and CD_shared = true", ShortcutType.shortcut.rawValue)
                ICloud.shared.download(
                                    recordType: "CD_\(CloudShortcutMO.tableName)",
                                    database: ICloud.shared.privateDatabase,
                                    keys: ["CD_sectionId", "CD_name"],
                                    sortKey: ["CD_sequence64"],
                                    predicate: predicate,
                                    downloadAction: { (record) in
                                                        shortcuts.append((record.value(forKey: "CD_sectionId") as! String, record.value(forKey: "CD_name") as! String))
                                                    },
                                    completeAction: {
                                                        buildList()
                                                    },
                                    failureAction: { (error) in
                                        fatalError(error!.localizedDescription)
                                    })
                            },
                failureAction: { (error) in
                    fatalError(error!.localizedDescription)
                })
    }
    
    private func buildList() {
        sharedList = []
        for section in sections {
            sharedList.append((true, section.name))
            let sectionShortcuts = shortcuts.filter({$0.sectionId == section.id})
            if sectionShortcuts.isEmpty {
                sharedList.append((false, "Nothing shared in this section"))
            }
            for shortcut in sectionShortcuts {
                sharedList.append((false, shortcut.name))
            }
        }
    }
}
