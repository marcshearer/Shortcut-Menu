//
//  Whisper View.swift
//  Shortcut Menu Mac
//
//  Created by Marc Shearer on 22/04/2020.
//  Copyright © 2020 Marc Shearer. All rights reserved.
//

import SwiftUI
import AudioToolbox

struct WhisperView: View {
    
    var header: String?
    var caption: String?
    var tight: Bool
    
    init(header: String? = nil, caption: String? = nil, tight: Bool = false) {
        self.header = header
        self.caption = caption
        self.tight = tight
        #if canImport(AppKit)
        NSSound(named: "Morse")?.play()
        #else
        AudioServicesPlayAlertSound(SystemSoundID(1304))
        #endif
    }
    
    var body: some View {
        HStack {
            Spacer().frame(width: tight ? 5 : 40)
            
            VStack(alignment: .center) {
                    Spacer().frame(height: tight ? 5 : 20)
                
                if self.header != nil {
                    
                    Text(self.header!)
                        .font(defaultFont)
                        .foregroundColor(Color(Palette.whisper.text.cgColor!))
        
                }
                
                if self.header != nil && self.caption != nil {
                    Spacer().frame(height: 10)
                }
                
                if self.caption != nil {
                    Text(self.caption!)
                        .font(captionFont)
                }
                
                Spacer().frame(height: tight ? 5 : 20)
                
            }
                
            Spacer().frame(width: tight ? 5 : 40)
        }
        .background(Palette.whisper.background)
    }
}
