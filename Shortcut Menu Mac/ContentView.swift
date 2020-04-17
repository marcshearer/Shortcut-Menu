//
//  ContentView.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 15/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    let selection = Selection(master: master)
    
    var body: some View {
        HStack(spacing: 0) {
            
            SectionList(selection: selection).frame(width: sectionWidth, height: formHeight, alignment: .leading)
            Divider()
                .background(Color.white)
                .frame(width: 2.0)
            ShortcutList(selection: selection).frame(width: shortcutWidth, height: formHeight, alignment: .leading)
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
