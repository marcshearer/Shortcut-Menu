//
//  SectionList.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct SectionList: View {
    
    @ObservedObject private var selection: Selection
    
    init(selection: Selection) {
        self.selection = selection
    }
    
    var body: some View {
        VStack(spacing: 0.0) {
            HStack {
                Spacer()
                Text("Sections")
                    .frame(width: sectionWidth, height: rowHeight, alignment: .leading)
                    .font(defaultFont)
            }
            .background(titleBackgroundColor)
            .foregroundColor(titleTextColor)
            List {
                ForEach (self.selection.sections) { (section) in
                        Text(section.name)
                            .frame(width: sectionWidth, height: rowHeight, alignment: .leading)
                            .font(defaultFont)
                            .listRowBackground((section.id == self.selection.selectedSection?.id ? sectionSelectionBackgroundColor : listBackgroundColor))
                            .foregroundColor((section.id == self.selection.selectedSection?.id ? sectionSelectionTextColor : listTextColor))
                            .onTapGesture {
                                _ = self.selection.selectSection(section: section)
                        }
                    }
            }
            .environment(\.defaultMinListRowHeight, rowHeight)
        }
    }
}

struct SectionList_Previews: PreviewProvider {
    static var previews: some View {
        SectionList(selection: Selection(master: master))
    }
}
