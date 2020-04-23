//
//  Whisper View.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 22/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI

struct WhisperView: View {
    
    var header: String?
    var caption: String?
    
    init(header: String? = nil, caption: String? = nil) {
        self.header = header
        self.caption = caption
        NSSound(named: "Morse")?.play()
    }
    
    var body: some View {
        HStack {
            Spacer()
                .frame(width: 40)
            
            VStack(alignment: .center) {
                Spacer()
                    .frame(height: 20)
                
                if self.header != nil {
                    
                    Text(self.header!)
                        .font(defaultFont)
                        .foregroundColor(Color(menuBarTextColor))
                    
                    Spacer()
                        .frame(height: 10)
                    
                }
                
                if self.caption != nil {
                    Text(self.caption!)
                        .font(captionFont)
                }
                
                Spacer()
                .frame(height: 20)
                
            }
                
            Spacer()
                .frame(width: 40)
        }
        .background(Color(red: 185/255, green: 201/255, blue: 249/255))
    }
}
