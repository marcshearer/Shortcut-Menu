//
//  Miscellanous.swift
//  Wots4T
//
//  Created by Marc Shearer on 02/03/2021.
//

import SwiftUI

class MessageBox : ObservableObject {
    
    public static let shared = MessageBox()
    
    @Published public var text: String?
    public var closeButton = false
    public var completion: (()->())? = nil
    
    public var isShown: Bool { MessageBox.shared.text != nil }
    
    public func show(_ text: String, closeButton: Bool = true, hideAfter: TimeInterval? = nil, completion: (()->())? = nil) {
        MessageBox.shared.text = text
        MessageBox.shared.closeButton = closeButton
        MessageBox.shared.completion = completion
        if let hideAfter = hideAfter {
            Utility.executeAfter(delay: hideAfter) {
                self.hide()
            }
        }
    }
    
    public func show(closeButton: Bool = true) {
        MessageBox.shared.closeButton = closeButton
    }
    
    public func hide() {
        MessageBox.shared.text = nil
    }
    
}

struct MessageBoxView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var values = MessageBox.shared
    @State var showIcon = true
    
    var body: some View {
        ZStack {
            Palette.background.background
                .ignoresSafeArea()
            HStack(spacing: 0) {
                if showIcon {
                    Spacer().frame(width: 30)
                        VStack {
                        Spacer()
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image("shortcut").resizable().frame(width: 60, height: 60)
                                Spacer()
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .frame(width: 80)
                }
                Spacer()
                VStack(alignment: .center) {
                    Spacer()
                    Text("Shortcuts").font(.largeTitle).minimumScaleFactor(0.75)
                    if let message = $values.text.wrappedValue {
                        Spacer().frame(height: 30)
                        Text(message).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true).font(.callout).minimumScaleFactor(0.5)
                    }
                    Spacer().frame(height: 30)
                    if MessageBox.shared.closeButton {
                        Button {
                            values.completion?()
                            $values.text.wrappedValue = nil
                        } label: {
                            Text("Close")
                                .foregroundColor(Palette.highlightButton.text)
                                .font(.callout).minimumScaleFactor(0.5)
                                .frame(width: 100, height: 30)
                                .background(Palette.highlightButton.background)
                                .cornerRadius(15)
                        }
                    } else {
                        Text("").frame(width: 100, height: 30)
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}
